\m4_TLV_version 1d: tl-x.org
\SV
   // This code can be found in: https://github.com/stevehoover/LF-Building-a-RISC-V-CPU-Core/risc-v_shell.tlv
   
   m4_include_lib(['https://raw.githubusercontent.com/stevehoover/LF-Building-a-RISC-V-CPU-Core/main/lib/risc-v_shell_lib.tlv'])


   //---------------------------------------------------------------------------------
   m4_test_prog()	//All register test
   //---------------------------------------------------------------------------------


\SV
   m4_makerchip_module   // (Expanded in Nav-TLV pane.)
   /* verilator lint_on WIDTH */
\TLV
   
   $reset = *reset;
   
   //Program Counter -- Sequential Only ATM
   $pc[31:0] = >>1$next_pc;
   $next_pc[31:0] = $reset ? 32'b0 :
    $taken_br ? $br_tgt_pc:
    $is_jal ? $br_tgt_pc:
    $is_jalr ? $jalr_tgt_pc:
    $pc+4;
   
   
   //IMem -- Instantiating a Verilog Macro
   `READONLY_MEM($pc, $$instr[31:0])
   
   //start Decode
   //opcode
   $is_i_instr = $instr[6:2] ==? 5'b0000x || $instr[6:2] ==? 5'b11001 || $instr[6:2] ==? 5'b001x0;
   $is_r_instr = $instr[6:2] ==? 5'b011x0 || $instr[6:2] ==? 5'b01011 || $instr[6:2] ==? 5'b10100;
   $is_s_instr = $instr[6:2] ==? 5'b0100x;
   $is_b_instr = $instr[6:2] ==? 5'b11000;
   $is_j_instr = $instr[6:2] ==? 5'b11011;
   $is_u_instr = $instr[6:2] ==? 5'b0x101;
   
   //instruction field
   $opcode[6:0] = $instr[6:0];
   $rs1[4:0] = $instr[19:15];
   $rs2[4:0] = $instr[24:20];
   $rd[4:0] = $instr[11:7];
   $func3[2:0] = $instr[14:12];
   
   //if_immediate -- i verified
   $imm[31:0] = $is_i_instr ? {{21{$instr[31]}}, $instr[30:20]} :
                $is_s_instr ? {{21{$instr[31]}}, $instr[30:25], $instr[11:8], $instr[7]} :
                $is_b_instr ? {{19{$instr[31]}}, {2{$instr[7]}}, $instr[30:25], $instr[11:8], 1'b0} :
                $is_u_instr ? {$instr[31:12], 12'b0} :
                $is_j_instr ? {{11{$instr[31]}}, $instr[19:12], {2{$instr[20]}}, $instr[30:25], $instr[24:21], 1'b0} :
                              32'b0;  // Default
   
   //if_valid
   $rd_valid = ($is_r_instr || $is_i_instr || $is_u_instr || $is_j_instr) && ($rd != 00);
   $rs1_valid = $is_r_instr || $is_i_instr || $is_s_instr || $is_b_instr;
   $rs2_valid = $is_r_instr || $is_s_instr || $is_b_instr;
   $func3_valid = $is_r_instr || $is_i_instr || $is_s_instr || $is_b_instr;
   $imm_valid = $is_i_instr || $is_s_instr || $is_b_instr || $is_u_instr || $is_j_instr;
   
   //Supress Warnings for Unused Signals
   `BOGUS_USE($opcode $rd $rd_valid $rs1 $rs1_valid $rs2 $rs2_valid $func3 $func3_valid $imm_valid $imm)
   
   //Instruction: func3
   $dec_bits[10:0] = {$instr[30],$func3,$opcode};
   $is_load = $dec_bits ==? 11'bx_xxx_0000011;
   //branch
   $is_beq = $dec_bits ==? 11'bx_000_1100011;
   $is_bne = $dec_bits ==? 11'bx_001_1100011;
   $is_blt = $dec_bits ==? 11'bx_100_1100011;
   $is_bge = $dec_bits ==? 11'bx_101_1100011;
   $is_bltu = $dec_bits ==? 11'bx_110_1100011;
   $is_bgeu = $dec_bits ==? 11'bx_111_1100011;
   //arithmetic
   $is_addi = $dec_bits ==? 11'bx_000_0010011;
   $is_add = $dec_bits ==? 11'b0_000_0110011;
   $is_sub = $dec_bits ==? 11'b1_000_0110011;
   $is_or = $dec_bits ==? 11'b0_110_0110011;
   $is_ori = $dec_bits ==? 11'bx_110_0010011;
   $is_andi = $dec_bits ==? 11'bx_111_0010011;
   $is_and = $dec_bits ==? 11'b0_111_0110011;
   $is_xor = $dec_bits ==? 11'b0_100_0110011;
   $is_xori = $dec_bits ==? 11'bx_100_0010011;
   $is_slt = $dec_bits ==? 11'b0_010_0110011;
   $is_slti = $dec_bits ==? 11'bx_010_0010011;
   $is_sltu = $dec_bits ==? 11'b0_011_0110011;
   $is_sltiu = $dec_bits ==? 11'bx_011_0010011;
   $is_sra = $dec_bits ==? 11'b1_101_0110011;
   $is_srai = $dec_bits ==? 11'b1_101_0010011;
   $is_sll = $dec_bits ==? 11'b0_001_0110011;
   $is_srl = $dec_bits ==? 11'b0_101_0110011;
   $is_slli = $dec_bits ==? 11'b0_001_0010011;
   $is_srli = $dec_bits ==? 11'b0_101_0010011;
   $is_lui = $dec_bits ==? 11'bx_xxx_0110111;
   $is_auipc = $dec_bits ==? 11'bx_xxx_0010111;
   $is_jal = $dec_bits ==? 11'bx_xxx_1101111;
   $is_jalr = $dec_bits ==? 11'bx_000_1100111;

   
   
   //Supress Warnings for Unused Signals
   `BOGUS_USE($dec_bits $is_beq $is_bne $is_blt $is_bge $is_bltu $is_bgeu $is_addi $is_add)
   //end Decode
   
   //SLTU (Set if less than, unsigned)
   $sltu_rslt[31:0] = {31'b0, $src1_value < $src2_value};
   $sltiu_rslt[31:0] = {31'b0, $src1_value < $imm};
   
   // SRA and SRAI (shift right,arithmetic) results:
   // sign-extended src1
   $sext_src1[63:0] = {{32{$src1_value[31]}}, $src1_value};
   // 64-bit sign-extended results. to be truncated
   $sra_rslt[63:0] = $sext_src1 >> $src2_value[4:0];
   $srai_rslt[63:0] = $sext_src1 >> $imm[4:0];
   
   //ALU(std+imm)
   //switch
   $result[31:0] =
     //arith
    $is_addi ? $src1_value + $imm:
    $is_add ? $src1_value + $src2_value:
    $is_sub ? $src1_value - $src2_value:
    //set - u/s for slt if diff sign, use src 1 sign
    $is_sltu ? $sltu_rslt:
    $is_sltiu ? $sltiu_rslt:
    $is_slt ? (($src1_value[31] == $src2_value[31]) ? $sltu_rslt : {31'b0, $src1_value[31]}):
    $is_slti ? (($src1_value[31] == $imm[31]) ? $sltu_rslt : {31'b0, $src1_value[31]}):
    //shift
    $is_sra ? $sra_rslt[31:0]:
    $is_srai ? $srai_rslt[31:0]:
    $is_sll ? $src1_value << $src2_value[4:0]:
    $is_slli ? $src1_value << $imm[4:0]:
    $is_srl ? $src1_value >> $src2_value[4:0]:
    $is_srli ? $src1_value >> $imm[4:0]:
    //logical
    $is_and ? $src1_value & $src2_value:
    $is_andi ? $src1_value & $imm:
    $is_or ? $src1_value | $src2_value:
    $is_ori ? $src1_value | $imm:
    $is_xor ? $src1_value ^ $src2_value:
    $is_xori ? $src1_value ^ $imm:
    //mem
    $is_lui ? {$imm[31:12],12'b0}:
    $is_load ? $rs1 + $imm: //get dmem addr
    $is_s_instr ? $rs1 + $imm:
    //pc
    $is_auipc ? $pc+$imm:
    $is_jal ? $pc + 32'd4:
    $is_jalr ? $pc + 32'd4:
               32'b0;
   
   //Result or Load Mux
   $result_rf[31:0] = $is_load ? $ld_data:
    $result;
   
   //Branch -- how to implement the 	unsigned part?
   $taken_br = 
    $is_beq ? ($src1_value == $src2_value ? 1'b1 : 1'b0):
    $is_bne ? ($src1_value != $src2_value ? 1'b1 : 1'b0):
    $is_blt ? (($src1_value < $src2_value) ^ ($src1_value[31] != $src2_value[31]) ? 1'b1 : 1'b0):
    $is_bge ? (($src1_value >= $src2_value) ^ ($src1_value[31] != $src2_value[31]) ? 1'b1 : 1'b0):
    $is_bltu ? ($src1_value < $src2_value ? 1'b1 : 1'b0):
    $is_bgeu ? ($src1_value >= $src2_value ? 1'b1 : 1'b0):
    1'b0;
   
   //Jump/Branch PC
   $br_tgt_pc[31:0] = $pc + $imm;
   $jalr_tgt_pc[31:0] = $src1_value + $imm;
   
   // Assert these to end simulation (before Makerchip cycle limit).
   *passed = 1'b0;
   *failed = *cyc_cnt > M4_MAX_CYC;
   
   m4+rf(32, 32, $reset, $rd_valid, $rd[4:0], $result_rf[31:0], $rs1_valid, $rs1[4:0], $src1_value, $rs2_valid, $rs2[4:0], $src2_value)
   m4+dmem(32, 32, $reset, $result[6:2], $is_s_instr, $src2_value[31:0], $is_load, $ld_data)
   m4+cpu_viz()
\SV
   endmodule