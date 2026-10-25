`timescale 1ns/1ps
`default_nettype none

module tb_f04;
    reg clk = 1'b0;
    reg rst_n = 1'b0;
    reg ena = 1'b0;
    reg [7:0] ui_in = 8'b0;
    reg [7:0] uio_in = 8'b0;
    wire [7:0] uo_out, uio_out, uio_oe;
    wire bit_in = uio_in[0];
    wire detect_mealy = uo_out[0];
    wire detect_moore = uo_out[1];
    wire [3:0] state_moore = uo_out[5:2];

    tt_um_f04_fsm_1011 dut (
        .ui_in(ui_in), .uo_out(uo_out), .uio_in(uio_in),
        .uio_out(uio_out), .uio_oe(uio_oe),
        .ena(ena), .clk(clk), .rst_n(rst_n)
    );
    always #5 clk = ~clk; // 10 ns demonstration period, not an Fmax result.

    // Independent reference: recent accepted bits, not an FSM case table.
    reg [3:0] history = 4'b0;
    integer valid_bits = 0;
    integer steps = 0;
    integer checks = 0;
    integer mealy_hits = 0;
    integer moore_hits = 0;
    integer trace_fd;
    integer mealy_coverage [0:7];
    integer moore_coverage [0:9];
    integer i, mealy_seen, moore_seen;
    reg [31:0] data_rng = 32'hF0410111;
    reg [31:0] noise_rng = 32'h13579BDF;
    string case_name = "initial_reset";

    function automatic [31:0] next_random(input [31:0] value);
        reg [31:0] t;
        begin
            t = value;
            t = t ^ (t << 13);
            t = t ^ (t >> 17);
            t = t ^ (t << 5);
            next_random = t;
        end
    endfunction

    function automatic reference_match(input [3:0] bits, input integer n);
        begin
            reference_match = (n >= 4) && (bits == 4'b1011);
        end
    endfunction

    function automatic [3:0] reference_state(input [3:0] bits, input integer n);
        begin
            if ((n >= 4) && (bits == 4'b1011))
                reference_state = 4'd4;
            else if ((n >= 3) && (bits[2:0] == 3'b101))
                reference_state = 4'd3;
            else if ((n >= 2) && (bits[1:0] == 2'b10))
                reference_state = 4'd2;
            else if ((n >= 1) && (bits[0] == 1'b1))
                reference_state = 4'd1;
            else
                reference_state = 4'd0;
        end
    endfunction

    function automatic [1:0] reference_mealy_state(input [3:0] bits, input integer n);
        begin
            if ((n >= 3) && (bits[2:0] == 3'b101))
                reference_mealy_state = 2'd3;
            else if ((n >= 2) && (bits[1:0] == 2'b10))
                reference_mealy_state = 2'd2;
            else if ((n >= 1) && (bits[0] == 1'b1))
                reference_mealy_state = 2'd1;
            else
                reference_mealy_state = 2'd0;
        end
    endfunction

    task automatic check_outputs(
        input string phase,
        input expected_mealy,
        input expected_moore,
        input [3:0] expected_state
    );
        begin
            checks = checks + 1;
            if (detect_mealy !== expected_mealy)
                $fatal(1, "FAIL case=%0s step=%0d phase=%0s bit=%0b ena=%0b rst_n=%0b Mealy expected=%0b actual=%0b history=%04b n=%0d",
                    case_name, steps, phase, bit_in, ena, rst_n,
                    expected_mealy, detect_mealy, history, valid_bits);
            if (detect_moore !== expected_moore)
                $fatal(1, "FAIL case=%0s step=%0d phase=%0s bit=%0b ena=%0b rst_n=%0b Moore expected=%0b actual=%0b history=%04b n=%0d",
                    case_name, steps, phase, bit_in, ena, rst_n,
                    expected_moore, detect_moore, history, valid_bits);
            if (state_moore !== expected_state)
                $fatal(1, "FAIL case=%0s step=%0d phase=%0s state expected=%0d actual=%0d history=%04b n=%0d",
                    case_name, steps, phase, expected_state,
                    state_moore, history, valid_bits);
            if (dut.u_mealy.state !== reference_mealy_state(history, valid_bits))
                $fatal(1, "FAIL case=%0s step=%0d phase=%0s Mealy state expected=%0d actual=%0d",
                    case_name, steps, phase,
                    reference_mealy_state(history, valid_bits), dut.u_mealy.state);
            // Invariants: unused outputs and bidirectional drive are zero.
            if ((uo_out[7:6] !== 2'b00) ||
                (uio_out !== 8'b0) || (uio_oe !== 8'b0))
                $fatal(1, "FAIL case=%0s step=%0d phase=%0s unused pins expected=0 actual uo[7:6]=%b uio_out=%h uio_oe=%h",
                    case_name, steps, phase, uo_out[7:6], uio_out, uio_oe);
        end
    endtask

    task automatic step(input bit_value, input enable_value, input reset_value);
        reg expected_hit, expected_before_moore, expected_after_mealy;
        reg before_mealy, before_moore;
        reg [3:0] old_state;
        integer m_index, q_index;
        begin
            // Drive halfway between accepting edges, avoiding a posedge race.
            @(negedge clk);
            rst_n = reset_value;
            ena = enable_value;
            noise_rng = next_random(noise_rng);
            ui_in = noise_rng[7:0];
            uio_in = {noise_rng[14:8], bit_value};
            steps = steps + 1;
            expected_hit = reset_value && enable_value &&
                           (valid_bits >= 3) &&
                           ({history[2:0], bit_value} == 4'b1011);
            expected_before_moore = reset_value && enable_value &&
                                    reference_match(history, valid_bits);
            old_state = reference_state(history, valid_bits);

            #4; // 1 ns before the next rising edge.
            check_outputs("before_edge", expected_hit,
                          expected_before_moore, old_state);
            before_mealy = detect_mealy;
            before_moore = detect_moore;
            if (reset_value && enable_value) begin
                m_index = {dut.u_mealy.state, bit_value};
                q_index = {dut.u_moore.state, bit_value};
                if ((m_index < 0) || (m_index > 7) ||
                    (q_index < 0) || (q_index > 9))
                    $fatal(1, "FAIL illegal internal state at step=%0d", steps);
                mealy_coverage[m_index] = mealy_coverage[m_index] + 1;
                moore_coverage[q_index] = moore_coverage[q_index] + 1;
            end
            if (before_mealy)
                mealy_hits = mealy_hits + 1;

            @(posedge clk);
            #1; // Observe after nonblocking state updates have settled.
            if (!reset_value) begin
                history = 4'b0;
                valid_bits = 0;
            end else if (enable_value) begin
                history = {history[2:0], bit_value};
                if (valid_bits < 4)
                    valid_bits = valid_bits + 1;
            end
            // Held input may affect the combinational Mealy level again
            // after state changes. That level is not a new accepted event.
            expected_after_mealy = reset_value && enable_value &&
                                   (valid_bits >= 3) &&
                                   ({history[2:0], bit_value} == 4'b1011);
            check_outputs("after_edge", expected_after_mealy,
                          reset_value && enable_value &&
                          reference_match(history, valid_bits),
                          reference_state(history, valid_bits));
            if (reset_value && enable_value && detect_moore)
                moore_hits = moore_hits + 1;
            $fdisplay(trace_fd, "%0d,%0s,%0d,%0b,%0b,%0b,%0b,%0b,%0b,%0b,%0b,%0d,%04b,%0d",
                $time, case_name, steps, bit_value, enable_value,
                reset_value, expected_hit, before_mealy, before_moore,
                detect_mealy, detect_moore, state_moore, history, valid_bits);
        end
    endtask

    task automatic reset_detector;
        begin
            step(1'b1, 1'b0, 1'b0); // Reset must win even when enable=0.
            step(1'b0, 1'b1, 1'b0);
        end
    endtask

    task automatic send_bits(input string bits);
        integer k;
        begin
            for (k = 0; k < bits.len(); k = k + 1) begin
                if (bits[k] == 8'h30)
                    step(1'b0, 1'b1, 1'b1);
                else if (bits[k] == 8'h31)
                    step(1'b1, 1'b1, 1'b1);
                else
                    $fatal(1, "FAIL non-binary test string");
            end
        end
    endtask

    task automatic run_case(input string label, input string bits,
                            input integer expected_hits);
        integer m_start, q_start;
        begin
            case_name = label;
            reset_detector();
            m_start = mealy_hits;
            q_start = moore_hits;
            send_bits(bits);
            if ((mealy_hits - m_start != expected_hits) ||
                (moore_hits - q_start != expected_hits))
                $fatal(1, "FAIL case=%0s expected_hits=%0d actual_mealy=%0d actual_moore=%0d",
                    label, expected_hits, mealy_hits-m_start, moore_hits-q_start);
            $display("CASE %0s bits=%0s Mealy=%0d Moore=%0d", label, bits,
                     mealy_hits-m_start, moore_hits-q_start);
        end
    endtask

    initial begin
        for (i = 0; i < 8; i = i + 1) mealy_coverage[i] = 0;
        for (i = 0; i < 10; i = i + 1) moore_coverage[i] = 0;
        trace_fd = $fopen("trace.csv", "w");
        if (trace_fd == 0) $fatal(1, "FAIL cannot create trace.csv");
        $fdisplay(trace_fd, "time_ns,case,step,bit,ena,rst_n,expected_accepted_match,mealy_before,moore_before,mealy_after,moore_after,moore_state,history,valid_bits");
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_f04);
        $display("F04 functional simulation: drive on negedge, accept on posedge; period=10ns is illustrative.");
        $display("SEEDS data=F0410111 unused_pin_noise=13579BDF");
        @(posedge clk);
        #1;
        check_outputs("initial_reset", 1'b0, 1'b0, 4'd0);

        // Required tests; 10111011 is adjacent, not an overlapping pair.
        run_case("required_1011", "1011", 1);
        run_case("required_10111011_adjacent", "10111011", 2);
        run_case("required_no_match", "000000001111111100000000", 0);
        // Added boundary cases catch lost history and sticky detections.
        run_case("added_true_overlap", "1011011", 2);
        run_case("added_three_adjacent", "101110111011", 3);
        run_case("added_near_match", "1010101010", 0);
        run_case("added_incomplete_prefix", "101", 0);

        case_name = "added_reset_mid_prefix";
        reset_detector();
        send_bits("101");
        step(1'b1, 1'b0, 1'b0);
        send_bits("1"); // Must not complete the prefix from before reset.
        send_bits("011"); // A new, post-reset 1011 is accepted here.

        case_name = "added_enable_pause";
        reset_detector();
        send_bits("101");
        step(1'b1, 1'b0, 1'b1); // Would match if mistakenly consumed.
        step(1'b0, 1'b0, 1'b1); // Must leave state/history unchanged.
        step(1'b1, 1'b1, 1'b1); // Resume: complete 1011.
        step(1'b0, 1'b0, 1'b1); // Hold S4, with external detects masked.
        step(1'b0, 1'b1, 1'b1); // Resume toward prefix 10.

        case_name = "random_1024_bits";
        reset_detector();
        for (i = 0; i < 1024; i = i + 1) begin
            data_rng = next_random(data_rng);
            step(data_rng[0], 1'b1, 1'b1);
        end
        case_name = "random_256_with_reset_and_enable";
        reset_detector();
        for (i = 0; i < 256; i = i + 1) begin
            data_rng = next_random(data_rng);
            step(data_rng[0], (data_rng[2:1] != 2'b00),
                 (data_rng[7:3] != 5'b00000));
        end

        mealy_seen = 0;
        moore_seen = 0;
        for (i = 0; i < 8; i = i + 1)
            if (mealy_coverage[i] > 0) mealy_seen = mealy_seen + 1;
        for (i = 0; i < 10; i = i + 1)
            if (moore_coverage[i] > 0) moore_seen = moore_seen + 1;
        if ((mealy_seen != 8) || (moore_seen != 10))
            $fatal(1, "FAIL transition coverage Mealy=%0d/8 Moore=%0d/10",
                mealy_seen, moore_seen);
        $fclose(trace_fd);
        $display("COVER state/input combinations Mealy=%0d/8 Moore=%0d/10", mealy_seen, moore_seen);
        $display("PASS F04 steps=%0d checks=%0d accepted_detections=%0d",
                 steps, checks, moore_hits);
        $finish;
    end
endmodule

`default_nettype wire
