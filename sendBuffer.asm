sendBufferAsm:

; 將給定的 ARM 組合語言代碼轉換為 RP2040 上的組合語言代碼

; 將寄存器保存到堆棧上
push {r4,r5,r6,r7,lr}

; 將緩沖區和引腳號保存到寄存器中
mov r4, r0 ; 保存緩沖區
mov r6, r1 ; 保存引腳

; 獲取緩沖區的長度
ldr r0, [r4, #4] ; 加載緩沖區地址中的長度
mov r5, r0       ; 保存緩沖區的長度到 r5 中

; 加載緩沖區的地址
ldr r0, [r4, #0] ; 加載緩沖區地址
mov r4, r0       ; 保存緩沖區的地址到 r4 中

; 加載引腳的地址
ldr r0, =0x40014030 ; RP2040 GPIO 控制器中 GPIO12 的地址
ldr r0, [r0, #0]    ; 加載 GPIO12 的地址到 r0 中

; 加載 GPIO 控制寄存器的地址
ldr r1, [r0, #0x4]  ; 加載 GPIO 控制寄存器的地址到 r1 中（設置高電平）
ldr r2, [r0, #0x8]  ; 加載 GPIO 控制寄存器的地址到 r2 中（設置低電平）

cpsid i ; 禁用 IRQ 中斷

b .start

.nextbit:
    str r1, [r1]    ; 引腳設置為高電平
    tst r6, r0      ; 檢查是否到達緩沖區結尾
    bne .islate     ; 如果沒有，則檢查是否為1
    b .stop         ; 如果到達結尾，則停止

.islate:
    lsrs r6, r6, #1 ; r6 右移一位
    bne .justbit    ; 如果 r6 不為零，則繼續處理下一個位

    ; 如果 r6 為零，則需要加載下一個字節
    adds r4, #1     ; 緩沖區地址加 1
    subs r5, #1     ; 緩沖區長度減 1
    bcc .stop       ; 如果緩沖區長度小於 0，則停止

.start:
    movs r6, #0x80  ; 重置掩碼
    nop             ; 空指令

.common:
    str r2, [r2]    ; 引腳設置為低電平
    ldrb r0, [r4]   ; 加載下一個字節到 r0 中
    b .nextbit     ; 處理下一個位

.justbit:
    b .common       ; 繼續處理下一個位

.stop:
    str r2, [r2]   ; 引腳設置為低電平
    cpsie i        ; 啟用 IRQ 中斷

    pop {r4,r5,r6,r7,pc} ; 恢復寄存器並返回
