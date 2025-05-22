section .data
    http_header_start db "HTTP/1.1 200 OK", 0x0D, 0x0A
                      db "Content-Type: text/plain", 0x0D, 0x0A
                      db "Content-Length: "
    http_header_start_len equ $ - http_header_start

    http_header_end db 0x0D, 0x0A, 0x0D, 0x0A
    http_header_end_len equ $ - http_header_end

    socket_msg db "socket started", 0x0A
    socket_msg_len equ $ - socket_msg

    bind_msg db "bind success", 0x0A
    bind_msg_len equ $ - bind_msg

    listen_msg db "listen success", 0x0A
    listen_msg_len equ $ - listen_msg

    accept_msg db "accept success", 0x0A
    accept_msg_len equ $ - accept_msg

    get_msg db "GET request", 0x0A
    get_msg_len equ $ - get_msg

    post_msg db "POST request", 0x0A
    post_msg_len equ $ - post_msg

    not_implemented_response db "HTTP/1.1 501 Not Implemented", 0x0D, 0x0A
                            db "Content-Length: 0", 0x0D, 0x0A, 0x0D, 0x0A
    not_implemented_response_len equ $ - not_implemented_response

    not_found_response db "HTTP/1.1 404 Not Found", 0x0D, 0x0A
                      db "Content-Type: text/plain", 0x0D, 0x0A
                      db "Content-Length: 9", 0x0D, 0x0A, 0x0D, 0x0A
                      db "Not Found"
    not_found_response_len equ $ - not_found_response

    parsed_method_msg db "Parsed Method: ", 0
    parsed_method_msg_len equ $ - parsed_method_msg

    parsed_path_msg db "Parsed Path: ", 0
    parsed_path_msg_len equ $ - parsed_path_msg

    full_path_msg db "Full Path: ", 0
    full_path_msg_len equ $ - full_path_msg

    public_prefix db "public/", 0
    
    mime_html db "Content-Type: text/html", 0x0D, 0x0A
    mime_html_len equ $ - mime_html

    mime_jpg db "Content-Type: image/jpeg", 0x0D, 0x0A
    mime_jpg_len equ $ - mime_jpg

    mime_js db "Content-Type: application/javascript", 0x0D, 0x0A
    mime_js_len equ $ - mime_js

    mime_plain db "Content-Type: text/plain", 0x0D, 0x0A
    mime_plain_len equ $ - mime_plain

    newline db 0x0A

    reuse_val dd 1 

    sockaddr_in:
        dw 2                   ; ip version (2 = IPv4)
        dw 0x901F              ; Port 8080 
        dd 0x00000000          ; 127.0.0.1 
        dq 0                   ; zero padding

section .bss
    buffer resb 1024
    method_name resb 10
    path resb 1024
    path_len resb 1024
    full_path resb 1024
    content_length_str resb 20  ; Buffer for content length string
    file_content resb 4096      ; Buffer for file content

section .text
    global _start
_start:
    ; socket()
    mov rax, 41              ; sys_socket
    mov rdi, 2               ; AF_INET
    mov rsi, 1               ; SOCK_STREAM
    xor rdx, rdx             ; protocol 0
    syscall
    cmp rax, 0
    jl exit_error
    mov r12, rax             ; save socket fd

    ; print "socket started"
    mov rax, 1
    mov rdi, 1
    mov rsi, socket_msg
    mov rdx, socket_msg_len
    syscall

    ; setsockopt
    mov rax, 54              ; sys_setsockopt
    mov rdi, r12             ; socket fd
    mov rsi, 1               ; SOL_SOCKET
    mov rdx, 2               ; SO_REUSEADDR
    mov r10, reuse_val       ; pointer to option value
    mov r8, 4                ; size of option
    syscall

    ; bind()
    mov rax, 49              ; sys_bind
    mov rdi, r12             ; socket fd
    mov rsi, sockaddr_in     ; sockaddr_in
    mov rdx, 16              ; sockaddr_in size
    syscall
    cmp rax, 0
    jl exit_error

    ; print "bind success"
    mov rax, 1
    mov rdi, 1
    mov rsi, bind_msg
    mov rdx, bind_msg_len
    syscall

    ; listen
    mov rax, 50
    mov rdi, r12
    mov rsi, 5
    syscall
    cmp rax, 0
    jl exit_error

    ; print "listen success"
    mov rax, 1
    mov rdi, 1
    mov rsi, listen_msg
    mov rdx, listen_msg_len
    syscall

accept_loop:
    ; accept
    mov rax, 43
    mov rdi, r12
    xor rsi, rsi
    xor rdx, rdx
    syscall
    cmp rax, 0
    jl exit_error
    mov r13, rax             

    ; print "accept success"
    mov rax, 1
    mov rdi, 1
    mov rsi, accept_msg
    mov rdx, accept_msg_len
    syscall

    jmp read_client

close_client:
    mov rax, 3               ; sys_close
    mov rdi, r13
    syscall
    jmp accept_loop

read_client:
    mov rax, 0               ; read
    mov rdi, r13
    mov rsi, buffer
    mov rdx, 1024
    syscall
    cmp rax, 0
    jle close_client
    mov r14, rax             ; store read length

    ; print client request to stdout
    mov rax, 1
    mov rdi, 1
    mov rsi, buffer
    mov rdx, r14
    syscall

    ; Check if it's a GET request
    mov al, [buffer]
    cmp al, 'G'
    jne write_not_implemented
    mov al, [buffer+1]
    cmp al, 'E'
    jne write_not_implemented
    mov al, [buffer+2]
    cmp al, 'T'
    jne write_not_implemented
    
    jmp handle_get_request

write_not_implemented:
    mov rax, 1               ; write
    mov rdi, r13
    mov rsi, not_implemented_response
    mov rdx, not_implemented_response_len
    syscall
    jmp close_client

handle_get_request:
    mov rax, 1
    mov rdi, 1
    mov rsi, get_msg
    mov rdx, get_msg_len
    syscall

    call parse_method_and_path

    ; Print "Parsed Method: "
    mov rax, 1
    mov rdi, 1
    mov rsi, parsed_method_msg
    mov rdx, parsed_method_msg_len
    syscall

    ; Print method_name
    mov rax, 1
    mov rdi, 1
    mov rsi, method_name
    mov rdx, 10            ; adjust if needed
    syscall

    ; Print newline
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall

    ; Print "Parsed Path: "
    mov rax, 1
    mov rdi, 1
    mov rsi, parsed_path_msg
    mov rdx, parsed_path_msg_len
    syscall

    ; Print path
    mov rax, 1
    mov rdi, 1
    mov rsi, path
    mov rdx, 1024          ; may be trimmed later
    syscall

    ; Print newline
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall

    ; Add null terminator to path for open syscall
    call null_terminate_path
    call build_full_path

    ; Print "Full Path: " for debugging
    mov rax, 1
    mov rdi, 1
    mov rsi, full_path_msg
    mov rdx, full_path_msg_len
    syscall

    ; Print full_path
    mov rax, 1
    mov rdi, 1
    mov rsi, full_path
    mov rdx, 1024
    syscall

    ; Print newline
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall

    ; Open file
    mov rax, 2             ; sys_open
    mov rdi, full_path     ; path buffer
    xor rsi, rsi           ; read-only
    syscall
    cmp rax, 0
    jl not_found
    mov r15, rax           ; store file descriptor

    ; Read file content into file_content buffer
    mov rdi, r15
    mov rax, 0             ; sys_read
    mov rsi, file_content
    mov rdx, 4096
    syscall
    mov r14, rax           ; store number of bytes read (content length)

    ; Close file
    mov rax, 3
    mov rdi, r15
    syscall

    ; Convert content length to string
    mov rax, r14           ; content length
    call int_to_string     ; result in content_length_str, length in rcx

    ; Debug: print content length to terminal with quotes
    push rcx
    mov rax, 1
    mov rdi, 1
    mov rsi, content_length_str
    mov rdx, rcx
    syscall
    
    ; Print newline for clarity
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall
    
    ; Debug: print the exact bytes being sent (first 10 bytes of header)
    mov rax, 1
    mov rdi, 1
    mov rsi, http_header_start
    mov rdx, 50  ; print first part of header
    syscall
    
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall
    pop rcx

    ; Send HTTP header start
    mov rax, 1
    mov rdi, r13
    mov rsi, http_header_start
    mov rdx, http_header_start_len
    syscall

    ; Send content length (using exact length)
    mov rax, 1
    mov rdi, r13
    mov rsi, content_length_str
    mov rdx, rcx           ; length of content length string
    syscall

    ; Send HTTP header end
    mov rax, 1
    mov rdi, r13
    mov rsi, http_header_end
    mov rdx, http_header_end_len
    syscall

    ; Send file content to client
    mov rax, 1
    mov rdi, r13
    mov rsi, file_content
    mov rdx, r14           ; actual content length
    syscall

    jmp close_client

not_found:
    mov rax, 1
    mov rdi, r13
    mov rsi, not_found_response
    mov rdx, not_found_response_len
    syscall
    jmp close_client

parse_method_and_path:
    ; Clear buffers first
    push rdi
    push rcx
    push rax
    
    ; Clear method_name
    mov rdi, method_name
    mov rcx, 10
    xor al, al
    rep stosb
    
    ; Clear path
    mov rdi, path
    mov rcx, 1024
    xor al, al
    rep stosb
    
    pop rax
    pop rcx
    pop rdi
    
    xor rsi, rsi       ; index of buffer
    xor rdi, rdi       ; index of method_name

.copy_method_name:
    mov al, [buffer+rsi] 
    cmp al, ' ' 
    je .skip_space
    mov [method_name+rdi], al 
    inc rsi 
    inc rdi 
    jmp .copy_method_name 

.skip_space:
    inc rsi
    
    ; Skip leading slash if present
    mov al, [buffer+rsi]
    cmp al, '/'
    jne .start_copy_path
    inc rsi

.start_copy_path:
    xor rdi, rdi

.copy_path:
    mov al, [buffer+rsi]
    cmp al, ' '
    je .done
    cmp al, 0x0A        ; newline
    je .done
    cmp al, 0x0D        ; carriage return
    je .done
    cmp al, '?'         ; query string start
    je .done
    mov [path+rdi], al
    inc rsi
    inc rdi
    cmp rdi, 1023       ; prevent buffer overflow
    jge .done
    jmp .copy_path

.done:
    ret

build_full_path:
    ; Clear full_path buffer first
    push rdi
    push rcx
    push rax
    
    mov rdi, full_path
    mov rcx, 1024
    xor al, al
    rep stosb
    
    pop rax
    pop rcx
    pop rdi

    ; Build full_path = "public/" + path
    mov rsi, public_prefix    ; Source: "public/"
    mov rdi, full_path        ; Destination buffer

.copy_prefix:
    mov al, [rsi]             ; Load character from public_prefix
    test al, al               ; Check if null terminator
    je .copy_path             ; If null, start copying path
    mov [rdi], al             ; Store character in destination
    inc rsi                   ; Move to next source character
    inc rdi                   ; Move to next destination position
    jmp .copy_prefix          ; Continue copying prefix

.copy_path:
    mov rsi, path             ; Switch to copying actual path

.copy_path_loop:
    mov al, [rsi]             ; Load character from path
    mov [rdi], al             ; Store in destination
    test al, al               ; Check if null terminator
    je .done                  ; If null, we're done
    inc rsi                   ; Move to next source character
    inc rdi                   ; Move to next destination position
    jmp .copy_path_loop       ; Continue copying path

.done:
    ret

null_terminate_path:
    xor rdi, rdi
.find_end:
    mov al, [path+rdi]
    cmp al, 0
    je .already_terminated
    cmp al, ' '
    je .terminate_here
    cmp al, 0x0A
    je .terminate_here
    cmp al, 0x0D
    je .terminate_here
    inc rdi
    cmp rdi, 1024
    jl .find_end
.terminate_here:
    mov byte [path+rdi], 0
.already_terminated:
    ret

int_to_string:
    push rbx
    push rdx
    push rsi
    
    ; Clear the entire buffer first
    push rdi
    push rcx
    push rax
    mov rdi, content_length_str
    mov rcx, 20
    xor al, al
    rep stosb
    pop rax
    pop rcx
    pop rdi
    
    ; Handle zero special case
    test rax, rax
    jnz .non_zero
    mov byte [content_length_str], '0'
    mov rcx, 1
    jmp .exit

.non_zero:
    mov rbx, 10
    xor rcx, rcx                ; digit counter
    mov rdi, content_length_str
    add rdi, 18                 ; point near end of buffer (leave room for null)

.digit_loop:
    xor rdx, rdx
    div rbx                     ; rax = quotient, rdx = remainder
    add dl, '0'                 ; convert remainder to ASCII
    mov [rdi], dl               ; store digit
    dec rdi                     ; move backward
    inc rcx                     ; count digits
    test rax, rax               ; check if more digits
    jnz .digit_loop

    ; Now copy to beginning of buffer
    inc rdi                     ; rdi now points to first digit
    mov rsi, rdi                ; source
    mov rdi, content_length_str ; destination
    
.copy_digits:
    mov al, [rsi]
    mov [rdi], al
    inc rsi
    inc rdi
    dec rcx
    jnz .copy_digits
    
    ; Ensure null termination
    mov byte [rdi], 0

    ; Calculate final length
    mov rcx, rdi
    sub rcx, content_length_str

.exit:
    pop rsi
    pop rdx
    pop rbx
    ret

detect_mime_type:
    ; Default
    mov rsi, mime_plain
    mov rcx, mime_plain_len

    ; Find end of path
    mov rdi, path
.find_end:
    mov al, [rdi]
    test al, al
    je .check
    inc rdi
    jmp .find_end

.check:
    ; rdi -> null byte
    ; check for ".html"
    cmp byte [rdi-5], '.'
    jne .check_jpg
    cmp dword [rdi-4], 'lmth'
    jne .check_jpg
    mov rsi, mime_html
    mov rcx, mime_html_len
    ret

.check_jpg:
    cmp byte [rdi-4], '.'
    jne .check_js
    cmp dword [rdi-3], 'gpj'
    jne .check_js
    mov rsi, mime_jpg
    mov rcx, mime_jpg_len
    ret

.check_js:
    cmp byte [rdi-3], '.'
    jne .done
    cmp word [rdi-2], 'sj'
    jne .done
    mov rsi, mime_js
    mov rcx, mime_js_len
    ret

.done:
    ret
    
exit_error:
    mov rax, 60
    mov rdi, 1
    syscall