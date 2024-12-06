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

	push 02000h ; zero out segment which will be used for storing list 1
	pop es
	xor di, di
	xor cx, cx
	dec cx
	xor al, al
	rep stosb
	push es
	pop fs ; use this segment as fs

	push 03000h ; zero out segment which will be used for storing list 2
	pop es ; use this segment as es
	xor di, di
	xor cx, cx
	dec cx
	xor al, al
	rep stosb

	lea si, buf

	xor di, di

newLine:
	call scanNumber
	mov fs:[di], eax
	call skipWhitespace
	call scanNumber
	mov es:[di], eax
	call skipWhitespace
	add di, 4
	inc word[numberOfLines]

	mov bx, si
	sub bx, buf
	cmp bx, word[bytesRead]
	jae endOfFile
	jmp newLine

endOfFile:

	xor si, si
	push fs
	pop ds
	mov cx, cs:word[numberOfLines]
	call sortDwordsDesc

	xor si, si
	push es
	pop ds
	mov cx, cs:word[numberOfLines]
	call sortDwordsDesc

	xor ebp, ebp
	
	mov cx, cs:word[numberOfLines]
	xor si, si
nextDifference:
	mov eax, fs:[si]
	mov ebx, es:[si]
	add si, 4
	sub eax, ebx
	jnc nonNegative
	neg eax
nonNegative:
	add ebp, eax 
	loop nextDifference

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

printSpace:
	push ax
	push dx
	
	mov ah, 02h
	mov dl, ' '
	int 21h
	
	pop dx
	pop ax
	
	ret


; in: dl=char to print
printChar:
	push ax
	push dx
	
	mov ah, 02h
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

; in: si=pointer to next char
; out: si=points to next non-whitespace character
skipWhitespace:
newChar:	
	lodsb
		
	cmp al, ' '
	je newChar
	cmp al, 0x0d
	je newChar
	cmp al, 0x0a
	je newChar

	dec si
	ret

; in: ds:si=start pointer cx=number of items
sortDwordsDesc:
	push si
	push di
	push eax
	push ebx
	push ecx
	push edx
	push es
	
	push ds
	pop es
	
	dec cx
	mov cs:word[sortItemCount], cx
	mov cs:word[sortStartPtr], si
	
nextSortIteration:
	mov dx, 0
	mov cx, cs:word[sortItemCount]
	mov si, cs:word[sortStartPtr]

nextSortItem:
	lodsd
	mov ebx, eax
	lodsd
	cmp eax, ebx
	jng noSwap 
swap:	
	sub si, 8
	mov di, si
	stosd
	mov eax, ebx
	stosd
	mov si, di
	mov dx, 1
noSwap:	
	sub si, 4
	loop nextSortItem
	
	cmp dx, 1
	je nextSortIteration
	
	pop es
	pop edx
	pop ecx
	pop ebx
	pop eax
	pop di
	pop si
	
	ret


fileName	db "input.txt", 0

bytesRead	dw 0
numberOfLines dw 0

sortItemCount	dw 0
sortStartPtr	dw 0

printBuf resb 256

buf:
