vsim -voptargs=+acc=rmb tb_cpu
add wave *
log -r /*
run -all