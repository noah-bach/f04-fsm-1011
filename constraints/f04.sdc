# Initial analysis assumptions: clock 10 ns, input/output delay 1 ns.
create_clock -name clk -period 10.0 [get_ports clk]

set_input_delay 1.0 -clock clk \
    [get_ports {ena rst_n ui_in* uio_in*}]

set_output_delay 1.0 -clock clk [all_outputs]
