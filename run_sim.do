vsim -voptargs=+acc=rmb tb_cpu
add wave *
add wave tb_cpu/regs
log -r /*
run -all
set DefaultRadix hex