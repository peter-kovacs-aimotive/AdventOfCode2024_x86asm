; Advent Of Code 2024
; Works on DosBox 0.74-3
; Compile with "nasm.exe fileName.asm -fbin -o fileName.com"

org 100h

	mov ax, 3d00h ; open file
	push cs
	pop ds
	lea dx, fileName
	int 21h ; ax = file handle
	
	mov bx, ax
	push bx
	mov ax, 3f00h ; read from file handle
	xor cx, cx
	dec cx
	lea dx, buf
	int 21h ; ax = number of bytes read from file
	mov word[bytesRead], ax

	pop bx
	mov ah, 3eh ; close file
	int 21h

	lea si, buf

nextLine:
	; collect numbers into a dword buffer
	push 02000h
	pop es
	push cs
	pop ds
	xor di, di
	xor cx, cx
readNextNumber:
	call scanNumber
	inc cx
	stosd
	mov al, cs:[si]
	inc si
	cmp al, ' '
	jne endOfLine
	jmp readNextNumber
endOfLine:
	add si, 1
	mov cs:word[numbersInLine], cx

	push si	

	xor ebp, ebp ; ebp now counts how many variations are safe
	xor si, si
	call checkSequence

	xor bx, bx ; which number not to copy

nextCombination:
	push 02000h
	pop ds
	push 03000h
	pop es
	xor si, si
	xor di, di
	mov cx, word[cs:numbersInLine]
copyNextNumber:
	mov eax, ds:[si]
	add si, 4
	cmp cx, bx
	je doNotCopy
	mov es:[di], eax
	add di, 4
doNotCopy:	
	loop copyNextNumber
	
	xor si, si
	dec word[cs:numbersInLine]
	call checkSequence
	inc word[cs:numbersInLine]

	inc bx
	mov ax, word[cs:numbersInLine]
	inc ax
	cmp bx, ax
	jne nextCombination

	cmp ebp, 0
	je didNotFindAny
	inc dword[cs:numberOfSafeLines]
didNotFindAny:

	pop si

	mov bx, si
	sub bx, buf
	cmp bx, word[cs:bytesRead]
	jae endOfFile
	
	jmp nextLine

endOfFile:

	mov ebp, dword[cs:numberOfSafeLines]
	call printResult
	call printNewLine
	ret


; input: ebp=number to print
printResult:
	pusha

	xor cx, cx ; cx = number of digits written to the buffer
	lea si, printBuf
	mov eax, ebp
	mov ebx, 10
printNextDigitToBuffer:
	xor edx, edx
	div ebx ; eax = quotient, edx = remainder
	push eax
	add dl, '0'
	mov [si], dl
	inc si
	inc cx
	pop eax
	test eax, eax
	jnz printNextDigitToBuffer

	dec si
printNextDigit:	
	mov ah, 02h
	mov dl, [si]
	int 21h
	dec si
	loop printNextDigit
	
	popa
	
	ret




printNewLine:
	push ax
	push dx
	
	mov ah, 02h
	mov dl, 10
	int 21h

	mov ah, 02h
	mov dl, 13
	int 21h
	
	pop dx
	pop ax
	
	ret


; in: si=pointer to number
; out: eax = number
;      ebx = number of digits
scanNumber:
newNumber:
	push edx
	push ecx
	push ebp
	
	xor ebx, ebx ; actual number
	xor ecx, ecx ; sign
	xor ebp, ebp ; number of digits
newDigit:	
	lodsb
		
	cmp al, '-'
	je negative
	cmp al, '0'
	jb notDigit
	cmp al, '9'
	ja notDigit
	sub al, '0'
	inc ebp
	xor ah, ah
	push ax

	mov eax, ebx
	mov ebx, 10
	mul ebx ; eax = eax*10
	mov ebx, eax
	xor eax,eax
	pop ax
	add ebx, eax
	jmp newDigit
negative:
	mov ecx, 1
	jmp newDigit
notDigit:
	cmp ecx, 0
	je positive
	neg ebx
positive:
	mov eax, ebx
	mov ebx, ebp
	
	pop ebp
	pop ecx
	pop edx
	dec si
	ret

; input es:si number sequence
; input word[numbersInLine]
checkSequence:
	push cx
	push si
	push dx
	push di
	push eax
	push ebx
	
	xor cx, cx
	xor si, si
	xor dx, dx ; increase
	xor di, di ; decrease

	mov eax, es:[si]
	add si, 4
	inc cx
nextNumber:
	mov ebx, eax
	mov cs:dword[referenceNumber], eax
	cmp cx, cs:word[numbersInLine]
	je goToNextLine
	push ebx

	mov eax, es:[si]
	add si, 4
	inc cx

	mov cs:dword[currentNumber], eax
	pop ebx
	cmp ebx, eax
	jg increase
	inc di
increase:	
	cmp ebx, eax
	jl decrease
	inc dx
decrease:
	cmp ebx, eax
	je sameNumber
	sub ebx, eax
	cmp ebx, 3
	jg tooBigIncrease
	mov ebx, cs:dword[referenceNumber]
	xchg ebx, eax
	sub ebx, eax
	cmp ebx, 3 ; cmp ebx, -3 does not compile as it should
	jg tooBigDecrease
	mov eax, cs:dword[currentNumber]
	mov cs:dword[referenceNumber], eax
	jmp nextNumber
	
sameNumber:	
tooBigIncrease:
tooBigDecrease:
	jmp notAllIncreaseOrDecrease

goToNextLine:
	mov ax, dx
	mul di
	cmp ax, 0
	jne notAllIncreaseOrDecrease
	inc ebp ; safe line
notAllIncreaseOrDecrease:
	
	pop ebx
	pop eax
	pop di
	pop dx
	pop si
	pop cx
	
	ret

fileName	db "input.txt", 0

bytesRead	dw 0
numberOfLines dw 0

numbersInLine dw 0

referenceNumber dd 0
currentNumber dd 0

numberOfSafeLines dd 0


printBuf resb 256

buf:
