sendBufferAsm:

    push {r4, r5, r6, r7, lr}

    mov r4, r0           ; 保存 buffer
    mov r6, r1           ; 保存 pin

    mov r0, r6
    movs r1, #0
    bl pins::pinByCfg   ; 获取引脚配置
    mov r6, r0           ; r6 - 引脚对象

    ; 设置 pin 为 digital
    mov r0, r6           ; 引脚对象
    movs r1, #1          ; 设置为高电平
    bl DigitalInOutPin::digitalWrite  ; 写入数字值

    ; 获取 pin 地址
    mov r0, r6
    bl DigitalInOutPin::getMicroBitPinAddress  ; 获取 MicroBitPin 地址

    ldr r0, [r0, #8]     ; 从 MicroBitPin 获取 mbed DigitalOut
    ldr r1, [r0, #4]     ; r1 - 该 pin 的掩码
    ldr r2, [r0, #16]    ; r2 - 清除地址
    ldr r3, [r0, #12]    ; r3 - 设置地址

    cpsid i              ; 禁用中断

    b .start

.nextbit:               ; C0
    str r1, [r3, #0]    ; pin := 高电平  C2
    tst r6, r0          ; 测试最高位  C3
    bne .islate         ; 如果最高位为 1  C4
    str r1, [r2, #0]    ; pin := 低电平  C6
.islate:
    lsrs r6, r6, #1     ; r6 >>= 1   C7
    bne .justbit        ; 如果还有位要发送  C8
    
    ; 不是只有一位，需要新字节
    adds r4, #1         ; r4++       C9
    subs r5, #1         ; r5--       C10
    bcc .stop           ; 如果 r5 < 0 跳转到 stop  C11
.start:
    movs r6, #0x80      ; 重置掩码  C12
    nop                 ; 空操作     C13

.common:               ; C13
    str r1, [r2, #0]   ; pin := 低电平   C15
    ; 始终重新加载字节 - 这样循环更紧凑
    ldrb r0, [r4, #0]  ; r0 := *r4   C17
    b .nextbit         ; 跳转到 nextbit  C20

.justbit: ; C10
    ; 无需空操作，分支已经占用 3 个周期
    b .common ; C13

.stop:    
    str r1, [r2, #0]   ; pin := 低电平
    cpsie i            ; 启用中断

    pop {r4, r5, r6, r7, pc}
