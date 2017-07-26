#!/usr/bin/env python3

import sys


def generate_f32_add(test_filename, lhs, rhs):
  test_file = open(test_filename, "w")
  out_filename = test_filename + '.out'

  # inputs
  test_file.write('''
	.section	.srodata.cst4,"aM",@progbits,4
	.align	2
''')
  test_file.write('  .Llhs: .word 0x' + lhs + '\n')
  test_file.write('  .Lrhs: .word 0x' + rhs + '\n')

  test_file.write('''
  .section  .rodata.str1.4,"aMS",@progbits,1
  .align  2
''')
  test_file.write('  .Lout_file: .string "' + out_filename + '"\n')
  test_file.write('  .align 2\n')
  test_file.write('  .Lout_mode: .string "w"\n')
  test_file.write('  .align 2\n')
  test_file.write('  .Linput_str: .string "' + lhs + ' ' + rhs + ' "\n')
  test_file.write('  .align 2\n')
  test_file.write('  .Lexcept_str: .string " 00\\n"\n')
  test_file.write('  .align 2\n')
  test_file.write('  .Lformat_str: .string "%08x"\n')

  # test code
  test_file.write('''
  .text
  .align 2
  .globl test
  .type test, @function
test:
  add   sp,sp,-4
  sw    ra,0(sp)

  lui   a5,%hi(.Llhs)
  lw    a0,%lo(.Llhs)(a5)
  lui   a5,%hi(.Lrhs)
  lw    a0,%lo(.Lrhs)(a5)
  call   __addsf3

  lw    ra,0(sp)
  add   sp,sp,4
  jr    ra
''')

  # main function
  test_file.write('''
	.section	.text.startup,"ax",@progbits
	.align	2
	.globl	main
	.type	main, @function
main:
  add   sp,sp,-16
  sw    ra,12(sp)

  lui   a0,%hi(.Lout_file)
  addi  a0,a0,%lo(.Lout_file)
  lui   a1,%hi(.Lout_mode)
  addi  a1,a1,%lo(.Lout_mode)
  call  fopen
  mv    s0,a0
  call  test

  mv    a2,a0
  mv    a0,sp
  lui   a1,%hi(.Lformat_str)
  addi  a1,a1,%lo(.Lformat_str)
  call  sprintf

  lui   a0,%hi(.Linput_str)
  addi  a0,a0,%lo(.Linput_str)
  li    a1,18
  li    a2,1
  mv    a3,s0
  call  fwrite

  mv    a0,sp
  li    a1,8
  li    a2,1
  mv    a3,s0
  call  fwrite

  lui   a0,%hi(.Lexcept_str)
  addi  a0,a0,%lo(.Lexcept_str)
  li    a1,4
  li    a2,1
  mv    a3,s0
  call  fwrite

  mv    a0,s0
  call  fclose

  lw    ra,12(sp)
  add   sp,sp,16
  jr    ra
''')


def main():
  assert (len(sys.argv) == 2)
  test = sys.argv[1]

  test_num = 0
  for line in sys.stdin:
    lhs, rhs, out, except_flags = line.split()

    test_filename = test + '_' + str(test_num) + '.s'
    test_num += 1

    if test == 'f32_add':
      generate_f32_add(test_filename, lhs, rhs)
    else:
      sys.stderr.write('Unknown test type\n')
      sys.exit(-1)
    sys.stdout.write(test_filename + '\n')


if __name__ == '__main__':
  main()

