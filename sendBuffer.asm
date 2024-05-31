push {r4,r5,r6,r7,lr}

mov r4, r0 ; 保存 buff
mov r6, r1 ; 保存 pin

mov r0, r4
bl BufferMethods::length
mov r5, r0

mov r0, r4
bl BufferMethods::getBytes
mov r4, r0

; 設置引腳為數位輸出
mov r0, #DAL.CFG_PIN_ACCELEROMETER_SCL
bl pins.pinByCfg
mov r0, r0, lsl #1 ; 加上 .digitalWrite 的偏移量

cpsid i ; 禁止 irq

b .start

.nextbit:
    str r0, [r0, #4] ; 引腳設置為高電平
    tst r6, r0
    bne .islate
    str r0, [r0, #8] ; 引腳設置為低電平
.islate:
    lsrs r6, r6, #1
    bne .justbit

    ; 不僅僅是一個位 - 需要新的字節
    adds r4, #1
    subs r5, #1
    bcc .stop
.start:
    movs r6, #0x80

.common:
    str r0, [r0, #8] ; 引腳設置為低電平
    ; 始終重新加載字節 - 這樣做更符合週期
    ldrb r0, [r4, #0]
    b .nextbit

.justbit:
    b .common

.stop:
    str r0, [r0, #8] ; 引腳設置為低電平
    cpsie i ; 啟用 irq

    pop {r4,r5,r6,r7,pc}
