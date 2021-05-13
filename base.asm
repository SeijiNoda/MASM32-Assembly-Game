; #########################################################################
;
;             GENERIC.ASM is a roadmap around a standard 32 bit 
;              windows application skeleton written in MASM32.
;
; #########################################################################

;           Assembler specific instructions for 32 bit ASM code

      .386                   ; minimum processor needed for 32 bit
      .model flat, stdcall   ; FLAT memory model & STDCALL calling
      option casemap :none   ; set code to case sensitive

; #########################################################################
      include \masm32\include\masm32rt.inc

      ; ---------------------------------------------
      ; main include file with equates and structures
      ; ---------------------------------------------
      include \masm32\include\windows.inc

      

      ; -------------------------------------------------------------
      ; In MASM32, each include file created by the L2INC.EXE utility
      ; has a matching library file. If you need functions from a
      ; specific library, you use BOTH the include file and library
      ; file for that library.
      ; -------------------------------------------------------------

      include \masm32\include\user32.inc
      include \masm32\include\kernel32.inc
      include \MASM32\INCLUDE\gdi32.inc

      include \MASM32\INCLUDE\Comctl32.inc
      include \MASM32\INCLUDE\comdlg32.inc
      include \MASM32\INCLUDE\shell32.inc
      INCLUDE \Masm32\Include\msimg32.inc
      INCLUDE \Masm32\Include\oleaut32.inc

      includelib \masm32\lib\user32.lib
      includelib \masm32\lib\kernel32.lib
      includelib \MASM32\LIB\gdi32.lib
      includelib \MASM32\LIB\Comctl32.lib
      includelib \MASM32\LIB\comdlg32.lib
      includelib \MASM32\LIB\shell32.lib

    INCLUDELIB \Masm32\Lib\msimg32.lib
    INCLUDELIB \Masm32\Lib\oleaut32.lib
    INCLUDELIB \Masm32\Lib\msvcrt.lib
    INCLUDELIB \Masm32\Lib\masm32.lib
; #########################################################################

; ------------------------------------------------------------------------
; MACROS are a method of expanding text at assembly time. This allows the
; programmer a tidy and convenient way of using COMMON blocks of code with
; the capacity to use DIFFERENT parameters in each block.
; ------------------------------------------------------------------------

      ; 1. szText
      ; A macro to insert TEXT into the code section for convenient and 
      ; more intuitive coding of functions that use byte data as text.

      szText MACRO Name, Text:VARARG
        LOCAL lbl
          jmp lbl
            Name db Text,0
          lbl:
        ENDM

      ; 2. m2m
      ; There is no mnemonic to copy from one memory location to another,
      ; this macro saves repeated coding of this process and is easier to
      ; read in complex code.

      m2m MACRO M1, M2
        push M2
        pop  M1
      ENDM

      ; 3. return
      ; Every procedure MUST have a "ret" to return the instruction
      ; pointer EIP back to the next instruction after the call that
      ; branched to it. This macro puts a return value in eax and
      ; makes the "ret" instruction on one line. It is mainly used
      ; for clear coding in complex conditionals in large branching
      ; code such as the WndProc procedure.

      return MACRO arg
        mov eax, arg
        ret
      ENDM

; #########################################################################

; ----------------------------------------------------------------------
; Prototypes are used in conjunction with the MASM "invoke" syntax for
; checking the number and size of parameters passed to a procedure. This
; improves the reliability of code that is written where errors in
; parameters are caught and displayed at assembly time.
; ----------------------------------------------------------------------

        WinMain PROTO :DWORD,:DWORD,:DWORD,:DWORD
        WndProc PROTO :DWORD,:DWORD,:DWORD,:DWORD
        TopXY PROTO   :DWORD,:DWORD

; #########################################################################

; ------------------------------------------------------------------------
; This is the INITIALISED data section meaning that data declared here has
; an initial value. You can also use an UNINIALISED section if you need
; data of that type [ .data? ]. Note that they are different and occur in
; different sections.
; ------------------------------------------------------------------------
.const
    ICONE   equ     500 ; define o numero associado ao icon igual ao arquivo RC
    ; define o numero da mensagem criada pelo usuario
    WM_FINISH equ WM_USER+100h  ; o numero da mensagem é a ultima + 100h
    img1    equ     100
    img2    equ     101
    img3    equ     103


    CREF_TRANSPARENT  EQU 00FFFFFFh


.data
        szDisplayName db "Monstrinho da Pati",0
        CommandLine   dd 0
        hWnd          dd 0
        hInstance     dd 0
        buffer        db 128 dup(0)
        X             dd 0
        Y             dd 0
        msg1          db "Mandou uma mensagem Ok",0
        contador      dd 0
        imgY          dd 100  
        imgX          dd 100  
        monY          dd 100
        monX          dd 100
; #########################################################################

.data?
        hitpoint    POINT <>
        hitpointEnd POINT <>
        threadID    DWORD ?  
        hEventStart HANDLE ?
        hBmpFundo   dd ?
        hBmpHeroi   dd ?
        hBmpMonstro dd ?

; ------------------------------------------------------------------------
; This is the start of the code section where executable code begins. This
; section ending with the ExitProcess() API function call is the only
; GLOBAL section of code and it provides access to the WinMain function
; with the necessary parameters, the instance handle and the command line
; address.
; ------------------------------------------------------------------------

    .code

; -----------------------------------------------------------------------
; The label "start:" is the address of the start of the code section and
; it has a matching "end start" at the end of the file. All procedures in
; this module must be written between these two.
; -----------------------------------------------------------------------

start:
    invoke GetModuleHandle, NULL ; provides the instance handle
    mov hInstance, eax

    invoke  GetCommandLine        ; provides the command line address
    mov     CommandLine, eax

    ; carrego o bitmap
    invoke LoadBitmap, hInstance, img1
    mov    hBmpHeroi, eax

    invoke LoadBitmap, hInstance, img2
    mov    hBmpMonstro, eax

    invoke LoadBitmap, hInstance, img3
    mov    hBmpFundo, eax

    ; eax tem o ponteiro para uma string que mostra toda linha de comando.
    ;invoke wsprintf,addr buffer,chr$("%s"), eax
    ;invoke MessageBox,NULL,ADDR buffer,ADDR szDisplayName,MB_OK

    invoke WinMain,hInstance,NULL,CommandLine,SW_SHOWDEFAULT
    
    invoke ExitProcess,eax       ; cleanup & return to operating system

; #########################################################################

WinMain proc hInst     :DWORD,
             hPrevInst :DWORD,
             CmdLine   :DWORD,
             CmdShow   :DWORD

        ;====================
        ; Put LOCALs on stack
        ;====================

        LOCAL wc   :WNDCLASSEX
        LOCAL msg  :MSG

        LOCAL Wwd  :DWORD
        LOCAL Wht  :DWORD
        LOCAL Wtx  :DWORD
        LOCAL Wty  :DWORD

        szText szClassName,"Generic_Class"

        ;==================================================
        ; Fill WNDCLASSEX structure with required variables
        ;==================================================

        mov wc.cbSize,         sizeof WNDCLASSEX
        mov wc.style,          CS_HREDRAW or CS_VREDRAW \
                               or CS_BYTEALIGNWINDOW
        mov wc.lpfnWndProc,    offset WndProc      ; address of WndProc
        mov wc.cbClsExtra,     NULL
        mov wc.cbWndExtra,     NULL
        m2m wc.hInstance,      hInst               ; instance handle
        mov wc.hbrBackground,  COLOR_BTNFACE+1     ; system color
        mov wc.lpszMenuName,   NULL
        mov wc.lpszClassName,  offset szClassName  ; window class name
        ; id do icon no arquivo RC
        invoke LoadIcon,hInst,500                  ; icon ID   ; resource icon
        mov wc.hIcon,          eax
          invoke LoadCursor,NULL,IDC_ARROW         ; system cursor
        mov wc.hCursor,        eax
        mov wc.hIconSm,        0

        invoke RegisterClassEx, ADDR wc     ; register the window class

        ;================================
        ; Centre window at following size
        ;================================

        mov Wwd, 512
        mov Wht, 512

        invoke GetSystemMetrics,SM_CXSCREEN ; get screen width in pixels
        invoke TopXY,Wwd,eax
        mov Wtx, eax

        invoke GetSystemMetrics,SM_CYSCREEN ; get screen height in pixels
        invoke TopXY,Wht,eax
        mov Wty, eax

        ; ==================================
        ; Create the main application window
        ; ==================================
        invoke CreateWindowEx,WS_EX_OVERLAPPEDWINDOW,
                              ADDR szClassName,
                              ADDR szDisplayName,
                              WS_OVERLAPPEDWINDOW,
                              Wtx,Wty,Wwd,Wht,
                              NULL,NULL,
                              hInst,NULL

        mov   hWnd,eax  ; copy return value into handle DWORD

        invoke LoadMenu,hInst,600                 ; load resource menu
        invoke SetMenu,hWnd,eax                   ; set it to main window

        invoke ShowWindow,hWnd,SW_SHOWNORMAL      ; display the window
        invoke UpdateWindow,hWnd                  ; update the display

      ;===================================
      ; Loop until PostQuitMessage is sent
      ;===================================

    StartLoop:
      invoke GetMessage,ADDR msg,NULL,0,0         ; get each message
      cmp eax, 0                                  ; exit if GetMessage()
      je ExitLoop                                 ; returns zero
      invoke TranslateMessage, ADDR msg           ; translate it
      invoke DispatchMessage,  ADDR msg           ; send it to message proc
      jmp StartLoop
    ExitLoop:

      return msg.wParam

WinMain endp

; #########################################################################

WndProc proc hWin   :DWORD,
             uMsg   :DWORD,
             wParam :DWORD,
             lParam :DWORD

    LOCAL hDC    :DWORD
    LOCAL Ps     :PAINTSTRUCT
    LOCAL rect   :RECT
    LOCAL Font   :DWORD
    LOCAL Font2  :DWORD
    LOCAL hOld   :DWORD

    LOCAL memDC  :DWORD

    ; cuidado ao declarar variaveis locais pois ao terminar o procedimento
    ; seu valor é limpado colocado lixo no lugar.
; -------------------------------------------------------------------------
; Message are sent by the operating system to an application through the
; WndProc proc. Each message can have additional values associated with it
; in the two parameters, wParam & lParam. The range of additional data that
; can be passed to an application is determined by the message.
; -------------------------------------------------------------------------

    .if uMsg == WM_COMMAND
    ;----------------------------------------------------------------------
    ; The WM_COMMAND message is sent by menus, buttons and toolbar buttons.
    ; Processing the wParam parameter of it is the method of obtaining the
    ; control's ID number so that the code for each operation can be
    ; processed. NOTE that the ID number is in the LOWORD of the wParam
    ; passed with the WM_COMMAND message. There may be some instances where
    ; an application needs to seperate the high and low words of wParam.
    ; ---------------------------------------------------------------------
    
    ;======== menu commands ========

        .if wParam == 1000
            invoke SendMessage,hWin,WM_SYSCOMMAND,SC_CLOSE,NULL
        .elseif wParam == 1001            
            mov eax, offset ThreadProc
            invoke CreateThread, NULL, NULL, eax,  \
                                 NULL, NORMAL_PRIORITY_CLASS, \
                                 ADDR threadID
            mov     contador, 0                                 


        .elseif wParam == 1900
            szText TheMsg,"Assembler, Pure & Simple"
            invoke MessageBox,hWin,ADDR TheMsg,ADDR szDisplayName,MB_OK
        .endif

    ;====== end menu commands ======
    .elseif uMsg == WM_LBUTTONDOWN
            mov eax,lParam
            and eax,0FFFFh
            mov hitpoint.x,eax
            mov eax,lParam
            shr eax,16
            mov hitpoint.y,eax

    .elseif uMsg == WM_LBUTTONUP
            mov eax,lParam
            and eax,0FFFFh
            mov hitpointEnd.x,eax
            mov eax,lParam
            shr eax,16
            mov hitpointEnd.y,eax
            invoke wsprintf,addr buffer,chr$("Posicao Inicial =  %d, %d Posicao Final =  %d, %d"), hitpoint.x, hitpoint.y,hitpointEnd.x,hitpointEnd.y
         ;   invoke MessageBox,hWin,ADDR buffer,ADDR szDisplayName,MB_OK
            invoke InvalidateRect, hWnd, NULL, FALSE
            mov   rect.left, 10
            mov   rect.top , 200
            mov   rect.right, 350
            mov   rect.bottom, 230
            invoke InvalidateRect, hWnd, addr rect, TRUE

    .elseif uMsg == WM_CHAR
            invoke wsprintf,addr buffer,chr$("LETRA =  %c"), wParam
            invoke MessageBox,hWin,ADDR buffer,ADDR szDisplayName,MB_OK
    .elseif uMsg == WM_KEYDOWN
            ;invoke wsprintf,addr buffer,chr$("Tecla codigo = %d"), wParam            
            ;invoke MessageBox,hWin,ADDR buffer,ADDR szDisplayName,MB_OK
            .if wParam == VK_UP
                .if imgY > 20
                  sub imgY, 5
                .endif
            .endif                 
            .if wParam == VK_DOWN
                .if imgY < 404
                  add imgY, 5
                .endif
            .endif          
            .if wParam == VK_LEFT
                .if imgX > 20
                  sub imgX, 5
                .endif
            .endif
            .if wParam == VK_RIGHT
                .if imgX < 440
                  add imgX, 5
                .endif
            .endif       
            
    .elseif uMsg == WM_FINISH
            ; aqui iremos desenhar sem chamar a função InvalideteRect
;            invoke GetDC, hWnd
;            mov    hDC, eax
                          
;            invoke ReleaseDC, hWin, hDC
            
            mov   rect.left, 100
            mov   rect.top , 100
            mov   rect.right, 32
            mov   rect.bottom, 32
            invoke InvalidateRect, hWnd, NULL, TRUE ;;addr rect, TRUE

    .elseif uMsg == WM_PAINT

            invoke BeginPaint,hWin,ADDR Ps
            ; aqui entra o desejamos desenha, escrever e outros.
            ; há uma outra maneira de fazer isso, mas veremos mais adiante.
            
            mov    hDC, eax

            invoke CreateCompatibleDC, hDC
            mov   memDC, eax
            invoke SelectObject, memDC, hBmpFundo
            mov  hOld, eax  
            invoke BitBlt, hDC, 0, 0,512,512, memDC, 10,10, SRCCOPY
            invoke SelectObject,hDC,hOld
            invoke DeleteDC,memDC  
            
            ; codigo para manipular a imagem bmp
            invoke CreateCompatibleDC, hDC
            mov  memDC, eax

            invoke SelectObject, memDC, hBmpHeroi
            mov  hOld, eax  

            ;invoke TransparentBlt, hDC, 190,100, 32,32, memDC, \
                       ;     0,32,32,32, CREF_TRANSPARENT
            
            invoke TransparentBlt, hDC, imgX,imgY, 32,32, memDC, \
                                    0,0,32,32, CREF_TRANSPARENT

            invoke SelectObject,hDC,hOld
            invoke DeleteDC,memDC  

            invoke CreateCompatibleDC, hDC
            mov   memDC, eax
            invoke SelectObject, memDC, hBmpMonstro
            mov  hOld, eax  

            invoke BitBlt, hDC, monX, monY,32,32, memDC, 0,0, SRCCOPY

            ;invoke BitBlt, hDC, 420, 100,32,32, memDC, 0,32, SRCCOPY

            ;invoke BitBlt, hDC, 74, 100,32,32, memDC, 0,32, SRCCOPY

            invoke TransparentBlt, hDC, monX, monY, 32,32, memDC, \
                                    0,0,32,32, CREF_TRANSPARENT

            invoke SelectObject,hDC,hOld
            invoke DeleteDC,memDC  
        

           


            invoke EndPaint,hWin,ADDR Ps
            return  0

    
            

    .elseif uMsg == WM_CREATE
    ; --------------------------------------------------------------------
    ; This message is sent to WndProc during the CreateWindowEx function
    ; call and is processed before it returns. This is used as a position
    ; to start other items such as controls. IMPORTANT, the handle for the
    ; CreateWindowEx call in the WinMain does not yet exist so the HANDLE
    ; passed to the WndProc [ hWin ] must be used here for any controls
    ; or child windows.
    ; --------------------------------------------------------------------
        mov     X,40
        mov     Y,60
        mov     imgY, 250
        mov     imgX, 100
        mov     monX, 250
        mov     monY, 250
        invoke  CreateEvent, NULL, FALSE, FALSE, NULL
        mov     hEventStart, eax
    
        mov eax, offset ThreadProc
        invoke CreateThread, NULL, NULL, eax,  \
                                 NULL, NORMAL_PRIORITY_CLASS, \
                                 ADDR threadID
        mov     contador, 0       

    .elseif uMsg == WM_CLOSE
 
    .elseif uMsg == WM_DESTROY
    ; ----------------------------------------------------------------
    ; This message MUST be processed to cleanly exit the application.
    ; Calling the PostQuitMessage() function makes the GetMessage()
    ; function in the WinMain() main loop return ZERO which exits the
    ; application correctly. If this message is not processed properly
    ; the window disappears but the code is left in memory.
    ; ----------------------------------------------------------------
        invoke PostQuitMessage,NULL
        return 0 
    .endif

    invoke DefWindowProc,hWin,uMsg,wParam,lParam
    ; --------------------------------------------------------------------
    ; Default window processing is done by the operating system for any
    ; message that is not processed by the application in the WndProc
    ; procedure. If the application requires other than default processing
    ; it executes the code when the message is trapped and returns ZERO
    ; to exit the WndProc procedure before the default window processing
    ; occurs with the call to DefWindowProc().
    ; --------------------------------------------------------------------

    ret

WndProc endp

; ########################################################################

TopXY proc wDim:DWORD, sDim:DWORD

    ; ----------------------------------------------------
    ; This procedure calculates the top X & Y co-ordinates
    ; for the CreateWindowEx call in the WinMain procedure
    ; ----------------------------------------------------

    shr sDim, 1      ; divide screen dimension by 2
    shr wDim, 1      ; divide window dimension by 2
    mov eax, wDim    ; copy window dimension into eax
    sub sDim, eax    ; sub half win dimension from half screen dimension

    return sDim

TopXY endp

; ########################################################################

ThreadProc PROC USES ecx Param:DWORD

  invoke WaitForSingleObject, hEventStart, 100
  .if eax == WAIT_TIMEOUT
    inc  contador
    invoke SendMessage, hWnd, WM_FINISH, NULL, NULL

  .endif
  jmp  ThreadProc
  ret  

ThreadProc ENDP 

end start
