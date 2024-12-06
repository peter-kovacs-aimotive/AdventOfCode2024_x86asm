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
	xor ebp, ebp

nextLine:
	xor dx, dx ; increase
	xor di, di ; decrease
	call scanNumber
nextNumber:
	mov ebx, eax
	mov cs:dword[referenceNumber], eax
	mov al, cs:[si]
	inc si
	cmp al, ' '
	jne goToNextLine
	push ebx
	call scanNumber
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
nextCharInLine:	
	mov al, cs:[si]
	inc si
	cmp al, 0x0d
	jnz nextCharInLine ; run till the end of the line
	jmp notAllIncreaseOrDecrease

goToNextLine:
	mov ax, dx
	mul di
	cmp ax, 0
	jne notAllIncreaseOrDecrease
	inc ebp ; safe line
notAllIncreaseOrDecrease:
	add si, 1

	mov bx, si
	sub bx, buf
	cmp bx, word[bytesRead]
	jae endOfFile
	
	jmp nextLine

endOfFile:

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


fileName	db "input.txt", 0

bytesRead	dw 0
numberOfLines dw 0

referenceNumber dd 0
currentNumber dd 0


printBuf resb 256

buf:
