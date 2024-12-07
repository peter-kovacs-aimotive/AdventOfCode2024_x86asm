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

nextChar:
	mov bx, si
	sub bx, buf
	cmp bx, word[bytesRead]
	jae endOfFile

	lodsb
	cmp al, 'm'
	je gotM
	cmp al, 'd'
	je gotD
	jmp nextChar
gotM:
	lodsb
	cmp al, 'u'
	jnz nextChar
	lodsb
	cmp al, 'l'
	jnz nextChar
	lodsb
	cmp al, '('
	jnz nextChar
	call scanNumber
	mov dword[cs:number1], eax
	lodsb
	cmp al, ','
	jnz nextChar
	call scanNumber
	mov dword[cs:number2], eax
	lodsb
	cmp al, ')'
	jnz nextChar
	
	cmp byte[cs:enabled], 0
	je doNotMultpily
	mov eax, dword[cs:number1]
	mov ebx, dword[cs:number2]
	mul ebx
	add ebp, eax
doNotMultpily:
	jmp nextChar

gotD:
	lodsb
	cmp al, 'o'
	je gotDO
	jmp nextChar
	
gotDO:
	lodsb
	cmp al, '('
	je gotDoOpen
	cmp al, 'n'
	je gotDON
	jmp nextChar
		
gotDoOpen:
	lodsb
	cmp al, ')'
	je gotDoOpenClose
	jmp nextChar

gotDoOpenClose:
	mov byte[cs:enabled], 1
	jmp nextChar

gotDON:
	lodsb
	cmp al, 27h
	je gotDONaposroph
	jmp nextChar

gotDONaposroph:
	lodsb
	cmp al, 't'
	je gotDONT
	jmp nextChar
	
gotDONT:
	lodsb
	cmp al, '('
	je gotDONTOpen
	jmp nextChar
	
gotDONTOpen:
	lodsb
	cmp al, ')'
	je gotDONTOpenClose
	jmp nextChar

gotDONTOpenClose:
	mov byte[cs:enabled], 0
	jmp nextChar


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
		
;	cmp al, '-'
;	je negative
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

printBuf resb 256

number1 dd 0
number2 dd 0

enabled db 1

buf:
