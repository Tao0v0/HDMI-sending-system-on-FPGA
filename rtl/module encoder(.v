module encoder(
input sys_clk,
input sys_rst_n,
input [7:0] din,
input de,
input c0,
input c1,
output reg[9:0]dout
);
 parameter CTRLTOKEN0 = 10'b1101010100;
 parameter CTRLTOKEN1 = 10'b0010101011;
 parameter CTRLTOKEN2 = 10'b0101010100;
 parameter CTRLTOKEN3 = 10'b1010101011;
reg [3:0]num_1;
reg [7:0]din_q;

always@(posedge sys_clk)
    num_1 <= din[0]+din[1]+din[2]+din[3]+din[4]+din[5]+din[6]+din[7];
    din_q <= din;
end

wire decision_1;
assign decision_1 = num_1>4||((num_1==4)&&(din_q[0]==0));

// 第一次8bit转换为9bit
wire [8:0]q_m;
assign q_m[0] = din_q[0];
assign q_m[1] = decision_1?(~(q_m[0]^din_q[1])):(q_m[0]^din_q[1]);
assign q_m[2] = decision_1?(~(q_m[1]^din_q[2])):(q_m[1]^din_q[2]);
assign q_m[3] = decision_1?(~(q_m[2]^din_q[3])):(q_m[2]^din_q[3]);
assign q_m[4] = decision_1?(~(q_m[3]^din_q[4])):(q_m[3]^din_q[4]);
assign q_m[5] = decision_1?(~(q_m[4]^din_q[5])):(q_m[4]^din_q[5]);
assign q_m[6] = decision_1?(~(q_m[5]^din_q[6])):(q_m[5]^din_q[6]);
assign q_m[7] = decision_1?(~(q_m[6]^din_q[7])):(q_m[6]^din_q[7]);
assign q_m[8] = decision_1?0:1;

reg [3:0] num1_q;
reg [3;0] num0_q;

// 计算9bit数据的0和1数量
always@(posedge sys_clk)
    num1_q <= q_m[0]+q_m[1]+q_m[2]+q_m[3]+q_m[4]+q_m[5]+q_m[6]+q_m[7];
    num0_q <= 4'h8-(q_m[0]+q_m[1]+q_m[2]+q_m[3]+q_m[4]+q_m[5]+q_m[6]+q_m[7]);
end

reg[4:0] cnt;
wire decision_2,decision_3;

assign decision_2 = (cnt == 0)||((num1_q)==(num0_q));
assign decision_3 = ((~cnt[4])&&(num1_q>num0_q))||((cnt[4])(num1_q<num0_q));

reg de_0,de_1;
reg c0_0,c1_0;
reg c0_1,c1_1;
reg [8:0]q_m_reg;

always@(posedge sys_clk)
    de_0 <= de;
    de_1 <= de_0;

    c0_0 <= c0;
    c0_1 <= c0_0;

    c1_0 <= c1;
    c1_1 <= c1_0;

    q_m_reg <= q_m;// 前面    din_q <= din; 延时了一个时钟，这里只需要再延时一次时钟，其余的延时两个时钟
end

always@(posedge sys_clk or posedge sys_rst_n)begin
    if(sys_rst_n)begin
        dout <= 0;
        cnt <= 5'd0;
    end
    else begin
        if(de_1) begin
            if(decision_2)begin
                dout[9] <= ~q_m_reg[8];
                dout[8] <= q_m_reg[8];
                dout[7:0] <= ((q_m_reg[8])?q_m_reg[7:0]:~q_m_reg[7:0]);
                cnt <= (q_m_reg[8])?(cnt+num1_q-num0_q):(cnt+num0_q-num1_q);
            end
            else begin
                if(decision_3)begin
                    dout[9] <= 1;
                    dout[8] <= q_m_reg[8];
                    dout[7:0] <= ~q_m_reg[7:0];
                    cnt <= cnt +2*q_m_reg[8]+num0_q-num1_q;
                end
                else begin
                    dout[9] <= 0;
                    dout[8] <= q_m_reg[8];
                    dout[7:0] <= q_m_reg[7:0];
                    cnt <= cnt - 2*(~q_m_reg[8]) +num1_q-num0_q;
                end
            end
        end
        else begin
            cnt <= 0;
            case({c1_1,c0_1})
            00:dout[9:0] <= CTRLTOKEN0;
            01:dout[9:0] <= CTRLTOKEN1;
            10:dout[9:0] <= CTRLTOKEN2;
            default:dout[9:0] <= CTRLTOKEN3;
            endcase
        end
    end
end
endmodule



