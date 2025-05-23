section .data
    http_header_start db "HTTP/1.1 200 OK", 0x0D, 0x0A
    http_header_start_len equ $ - http_header_start

    content_length_msg db "Content-Length: ", 0
    content_length_msg_len equ $ - content_length_msg

    change_line db 0x0D, 0x0A
    change_line_len equ $ - change_line

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

    mime_css db "Content-Type: text/css", 0x0D, 0x0A
    mime_css_len equ $ - mime_css

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
    file_content resb 4096

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
    
    call parse_method_and_path

    ; Check if it's a GET request
    mov rax, [method_name]   
    cmp rax, 'GET'           
    jne send_not_implemented
    jmp handle_get_request

send_not_implemented:
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

    mov rax, 1
    mov rdi, 1
    mov rsi, parsed_method_msg
    mov rdx, parsed_method_msg_len
    syscall

    mov rax, 1
    mov rdi, 1
    mov rsi, method_name
    mov rdx, 10
    syscall

    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall

    mov rax, 1
    mov rdi, 1
    mov rsi, parsed_path_msg
    mov rdx, parsed_path_msg_len
    syscall

    mov rax, 1
    mov rdi, 1
    mov rsi, path
    mov rdx, 1024
    syscall

    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall

    call build_full_path

    mov rax, 1
    mov rdi, 1
    mov rsi, full_path_msg
    mov rdx, full_path_msg_len
    syscall

    mov rax, 1
    mov rdi, 1
    mov rsi, full_path
    mov rdx, 1024
    syscall

    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall

    mov rax, 2             
    mov rdi, full_path     
    xor rsi, rsi           
    syscall
    cmp rax, 0
    jl not_found
    mov r15, rax           

    mov rdi, r15
    mov rax, 0             
    mov rsi, file_content
    mov rdx, 2048
    syscall
    mov r14, rax           

    mov rax, 3
    mov rdi, r15
    syscall

    mov rax, r14            

    mov rax, 1
    mov rdi, r13
    mov rsi, http_header_start
    mov rdx, http_header_start_len
    syscall

    call detect_mime_type
    mov rax, 1
    mov rdi, r13
    mov rdx, rcx
    syscall

    mov rax, 1
    mov rdi, r13
    mov rsi, change_line
    mov rdx, change_line_len
    syscall
    
    mov rax, 1
    mov rdi, r13
    mov rsi, change_line
    mov rdx, change_line_len
    syscall

    mov rax, 1
    mov rdi, r13
    mov rsi, file_content
    mov rdx, r14
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
    push rdi
    push rcx
    push rax
    
    mov rdi, method_name
    mov rcx, 10
    xor al, al
    rep stosb
    
    mov rdi, path
    mov rcx, 1024
    xor al, al
    rep stosb
    
    pop rax
    pop rcx
    pop rdi
    
    xor rsi, rsi       
    xor rdi, rdi       

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
    mov [path+rdi], al
    inc rsi
    inc rdi
    jmp .copy_path

.done:
    ret

build_full_path:
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

    mov rsi, path
    mov al, [rsi]
    cmp al, 0
    je .done

    mov rsi, public_prefix    
    mov rdi, full_path        

.copy_prefix:
    mov al, [rsi]             
    test al, al               
    je .copy_path             
    mov [rdi], al             
    inc rsi                   
    inc rdi                   
    jmp .copy_prefix          

.copy_path:
    mov rsi, path             

.copy_path_loop:
    mov al, [rsi]             
    mov [rdi], al             
    test al, al               
    je .done                  
    inc rsi                   
    inc rdi                   
    jmp .copy_path_loop       

.done:
    ret

detect_mime_type:
    mov rsi, mime_plain
    mov rcx, mime_plain_len

    mov rdi, path

.find_end:
    mov al, [rdi]
    test al, al
    je .check
    inc rdi
    jmp .find_end

.check:    
    mov rsi, rdi
    sub rsi, 5                  
    
    cmp byte [rsi], '.'
    jne .check_jpg
    cmp byte [rsi+1], 'h'
    jne .check_jpg
    cmp byte [rsi+2], 't'
    jne .check_jpg
    cmp byte [rsi+3], 'm'
    jne .check_jpg
    cmp byte [rsi+4], 'l'
    jne .check_jpg
    
    mov rsi, mime_html
    mov rcx, mime_html_len
    ret

.check_jpg:
    mov rsi, rdi
    sub rsi, 4                  
    cmp byte [rsi], '.'
    jne .check_js
    cmp byte [rsi+1], 'j'
    jne .check_js
    cmp byte [rsi+2], 'p'
    jne .check_js
    cmp byte [rsi+3], 'g'
    jne .check_js
    
    mov rsi, mime_jpg
    mov rcx, mime_jpg_len
    ret

.check_js:
    
    mov rsi, rdi
    sub rsi, 3                  
    
    cmp byte [rsi], '.'
    jne .done
    cmp byte [rsi+1], 'j'
    jne .done
    cmp byte [rsi+2], 's'
    jne .done
    
    mov rsi, mime_js
    mov rcx, mime_js_len
    ret

.done:
    mov rdi, rsi
    mov rdx, rcx
    syscall

    ret
    
exit_error:
    mov rax, 60
    mov rdi, 1
    syscall