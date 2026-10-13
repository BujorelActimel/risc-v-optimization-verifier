	.file	"strength_reduction.c"
	.option nopic
	.attribute arch, "rv32i2p1"
	.attribute unaligned_access, 0
	.attribute stack_align, 16
	.text
	.align	2
	.globl	mul4_original
	.type	mul4_original, @function
mul4_original:
	addi	sp,sp,-32
	sw	ra,28(sp)
	sw	s0,24(sp)
	addi	s0,sp,32
	sw	a0,-20(s0)
	lw	a5,-20(s0)
	slli	a5,a5,2
	mv	a0,a5
	lw	ra,28(sp)
	lw	s0,24(sp)
	addi	sp,sp,32
	jr	ra
	.size	mul4_original, .-mul4_original
	.align	2
	.globl	mul4_optimized
	.type	mul4_optimized, @function
mul4_optimized:
	addi	sp,sp,-32
	sw	ra,28(sp)
	sw	s0,24(sp)
	addi	s0,sp,32
	sw	a0,-20(s0)
	lw	a5,-20(s0)
	slli	a5,a5,2
	mv	a0,a5
	lw	ra,28(sp)
	lw	s0,24(sp)
	addi	sp,sp,32
	jr	ra
	.size	mul4_optimized, .-mul4_optimized
	.ident	"GCC: (GNU) 16.2.0"
	.section	.note.GNU-stack,"",@progbits
