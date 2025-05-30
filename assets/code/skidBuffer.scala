package d2d.common

import chisel3._
import chisel3.util._

class skidBuffer(DW: Int,
                 OPT_LOWPOWER: Boolean,
                 OPT_OUTREG : Boolean) extends Module {
  val io = IO(new Bundle {
    val i_data  = Flipped(Decoupled(UInt(DW.W)))
    val o_data =  Decoupled(UInt(DW.W))
  })
  val OPT_LOWPOWERReg = RegInit(OPT_LOWPOWER.B)
  val OPT_OUTREGReg = RegInit(OPT_OUTREG.B)
  val r_valid = RegInit(false.B)
  val r_data = RegInit(0.U(DW.W))

  //cant comsume data immediately
  when(io.i_data.fire && (io.o_data.valid && !io.o_data.ready)){
    r_valid := true.B
  }.elsewhen(io.o_data.ready){
    r_valid := false.B
  }.otherwise{
    r_valid := r_valid
  }

  when(OPT_LOWPOWERReg && (!io.o_data.valid || io.o_data.ready)){
    r_data := 0.U
  }.elsewhen((!OPT_LOWPOWERReg || !OPT_OUTREGReg || io.i_data.valid) && io.i_data.ready){
    r_data := io.i_data.bits
  }
  io.i_data.ready := !r_valid

  if(!OPT_OUTREG){
    // Outputs are combinatorially determined from inputs
    // o_valid
    io.o_data.valid := (!reset.asBool() && (io.i_data.valid || r_valid))

    // o_data
    when (r_valid){
      io.o_data.bits := r_data
    }.elsewhen(!OPT_LOWPOWERReg || io.i_data.valid){
      io.o_data.bits := io.i_data.bits
    }.otherwise{
      io.o_data.bits := 0.U
    }
  }else{
    val ro_valid = RegInit(false.B)
    val ro_data = RegInit(0.U(DW.W))
    when(!io.o_data.valid || io.o_data.ready){
      ro_valid := (io.i_data.valid || r_valid)
    }
    io.o_data.valid := ro_valid

    // o_data
    when(!io.o_data.valid || io.o_data.ready){
      when (r_valid){
        ro_data := r_data
      }.elsewhen (!OPT_LOWPOWERReg || io.i_data.valid){
        ro_data := io.i_data.bits
      }.otherwise{
        ro_data := 0.U
      }
    }
    io.o_data.bits := ro_data
  }
}
