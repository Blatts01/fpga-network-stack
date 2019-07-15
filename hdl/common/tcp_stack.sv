`timescale 1ns / 1ps
`default_nettype none

`include "os_types.svh"

module tcp_stack #(
    parameter TCP_EN = 1,
    parameter WIDTH = 64,
    parameter RX_DDR_BYPASS_EN = 0
)(
    input wire          net_clk,
    input wire          net_aresetn,
    
    // network interface streams
    axi_stream.slave        s_axis_rx_data,
    axi_stream.master       m_axis_tx_data,

    //TCP Interface
    // memory cmd streams
    axis_mem_cmd.master    m_axis_mem_read_cmd[NUM_TCP_CHANNELS],
    axis_mem_cmd.master    m_axis_mem_write_cmd[NUM_TCP_CHANNELS],
    // memory sts streams
    axis_mem_status.slave     s_axis_mem_read_sts[NUM_TCP_CHANNELS],
    axis_mem_status.slave     s_axis_mem_write_sts[NUM_TCP_CHANNELS],
    // memory data streams
    axi_stream.slave    s_axis_mem_read_data[NUM_TCP_CHANNELS],
    axi_stream.master   m_axis_mem_write_data[NUM_TCP_CHANNELS],
    
    
    //Application interface streams
    axis_meta.slave     s_axis_listen_port,
    axis_meta.master    m_axis_listen_port_status,
   
    axis_meta.slave     s_axis_open_connection,
    axis_meta.master    m_axis_open_status,
    axis_meta.slave     s_axis_close_connection,

    axis_meta.master    m_axis_notifications,
    axis_meta.slave     s_axis_read_package,
    
    axis_meta.master    m_axis_rx_metadata,
    axi_stream.master   m_axis_rx_data,
    
    axis_meta.slave     s_axis_tx_metadata,
    axi_stream.slave    s_axis_tx_data,
    axis_meta.master    m_axis_tx_status,


   input wire[127:0]    local_ip_address,
   output logic      session_count_valid,
   output logic[15:0]   session_count_data
   //output logic      psn_drop_pkg_count_valid,
   //output logic[31:0]   psn_drop_pkg_count_data


 );

localparam ddrPortNetworkRx = 1;
localparam ddrPortNetworkTx = 0;

generate
if (TCP_EN == 1) begin

// SmartCAM signals
wire        upd_req_TVALID;
wire        upd_req_TREADY;
wire[111:0] upd_req_TDATA; //(1 + 1 + 14 + 96) - 1 = 111
wire        upd_rsp_TVALID;
wire        upd_rsp_TREADY;
wire[15:0]  upd_rsp_TDATA;

wire        ins_req_TVALID;
wire        ins_req_TREADY;
wire[111:0] ins_req_TDATA;
wire        del_req_TVALID;
wire        del_req_TREADY;
wire[111:0] del_req_TDATA;

wire        lup_req_TVALID;
wire        lup_req_TREADY;
wire[97:0]  lup_req_TDATA; //should be 96, also wrong in SmartCam
wire        lup_rsp_TVALID;
wire        lup_rsp_TREADY;
wire[15:0]  lup_rsp_TDATA;

 //TODO
//logic[15:0] regSessionCount_V;
//logic       regSessionCount_V_ap_vld;

//TODO fix generate
//generate
if (RX_DDR_BYPASS_EN == 1) begin
    //RX Buffer bypass data streams
    wire axis_rxbuffer2app_tvalid;
    wire axis_rxbuffer2app_tready;
    wire[63:0] axis_rxbuffer2app_tdata;
    wire[7:0] axis_rxbuffer2app_tkeep;
    wire axis_rxbuffer2app_tlast;
    
    wire axis_tcp2rxbuffer_tvalid;
    wire axis_tcp2rxbuffer_tready;
    wire[63:0] axis_tcp2rxbuffer_tdata;
    wire[7:0] axis_tcp2rxbuffer_tkeep;
    wire axis_tcp2rxbuffer_tlast;
    
    wire[31:0] rx_buffer_data_count;
end
else begin
    assign s_axis_read_sts[ddrPortNetworkRx].ready = 1'b1;
end
//endgenerate

assign s_axis_read_sts[ddrPortNetworkTx].ready = 1'b1;


//hack for now //TODO
wire[71:0] axis_write_cmd_data [1:0];
wire[71:0] axis_read_cmd_data [1:0];
//generate
if (RX_DDR_BYPASS_EN == 0) begin
    assign m_axis_write_cmd[ddrPortNetworkRx].address = axis_write_cmd_data[ddrPortNetworkRx][63:32];
    assign m_axis_write_cmd[ddrPortNetworkRx].length = axis_write_cmd_data[ddrPortNetworkRx][22:0];
    assign m_axis_read_cmd[ddrPortNetworkRx].address = axis_read_cmd_data[ddrPortNetworkRx][63:32];
assign m_axis_read_cmd[ddrPortNetworkRx].length = axis_read_cmd_data[ddrPortNetworkRx][22:0];
end
//endgenerate
assign m_axis_write_cmd[ddrPortNetworkTx].address = axis_write_cmd_data[ddrPortNetworkTx][63:32];
assign m_axis_write_cmd[ddrPortNetworkTx].length = axis_write_cmd_data[ddrPortNetworkTx][22:0];
assign m_axis_read_cmd[ddrPortNetworkTx].address = axis_read_cmd_data[ddrPortNetworkTx][63:32];
assign m_axis_read_cmd[ddrPortNetworkTx].length = axis_read_cmd_data[ddrPortNetworkTx][22:0];



toe_ip toe_inst (
// Data output
.m_axis_tcp_data_TVALID(axis_toe_to_toe_slice.valid),
.m_axis_tcp_data_TREADY(axis_toe_to_toe_slice.ready),
.m_axis_tcp_data_TDATA(axis_toe_to_toe_slice.data), // output [63 : 0] AXI_M_Stream_TDATA
.m_axis_tcp_data_TKEEP(axis_toe_to_toe_slice.keep),
.m_axis_tcp_data_TLAST(axis_toe_to_toe_slice.last),
// Data input
.s_axis_tcp_data_TVALID(axis_toe_slice_to_toe.valid),
.s_axis_tcp_data_TREADY(axis_toe_slice_to_toe.ready),
.s_axis_tcp_data_TDATA(axis_toe_slice_to_toe.data),
.s_axis_tcp_data_TKEEP(axis_toe_slice_to_toe.keep),
.s_axis_tcp_data_TLAST(axis_toe_slice_to_toe.last),
`ifndef RX_DDR_BYPASS
// rx read commands
.m_axis_rxread_cmd_TVALID(m_axis_read_cmd[ddrPortNetworkRx].valid),
.m_axis_rxread_cmd_TREADY(m_axis_read_cmd[ddrPortNetworkRx].ready),
.m_axis_rxread_cmd_TDATA(axis_read_cmd_data[ddrPortNetworkRx]),
// rx write commands
.m_axis_rxwrite_cmd_TVALID(m_axis_write_cmd[ddrPortNetworkRx].valid),
.m_axis_rxwrite_cmd_TREADY(m_axis_write_cmd[ddrPortNetworkRx].ready),
.m_axis_rxwrite_cmd_TDATA(axis_write_cmd_data[ddrPortNetworkRx]),
// rx write status
.s_axis_rxwrite_sts_TVALID(s_axis_write_sts[ddrPortNetworkRx].valid),
.s_axis_rxwrite_sts_TREADY(s_axis_write_sts[ddrPortNetworkRx].ready),
.s_axis_rxwrite_sts_TDATA(s_axis_write_sts[ddrPortNetworkRx].data),
// rx buffer read path
.s_axis_rxread_data_TVALID(axis_rxread_data.valid),
.s_axis_rxread_data_TREADY(axis_rxread_data.ready),
.s_axis_rxread_data_TDATA(axis_rxread_data.data),
.s_axis_rxread_data_TKEEP(axis_rxread_data.keep),
.s_axis_rxread_data_TLAST(axis_rxread_data.last),
// rx buffer write path
.m_axis_rxwrite_data_TVALID(axis_rxwrite_data.valid),
.m_axis_rxwrite_data_TREADY(axis_rxwrite_data.ready),
.m_axis_rxwrite_data_TDATA(axis_rxwrite_data.data),
.m_axis_rxwrite_data_TKEEP(axis_rxwrite_data.keep),
.m_axis_rxwrite_data_TLAST(axis_rxwrite_data.last),
`else
// rx buffer read path
.s_axis_rxread_data_TVALID(axis_rxbuffer2app_tvalid),
.s_axis_rxread_data_TREADY(axis_rxbuffer2app_tready),
.s_axis_rxread_data_TDATA(axis_rxbuffer2app_tdata),
.s_axis_rxread_data_TKEEP(axis_rxbuffer2app_tkeep),
.s_axis_rxread_data_TLAST(axis_rxbuffer2app_tlast),
// rx buffer write path
.m_axis_rxwrite_data_TVALID(axis_tcp2rxbuffer_tvalid),
.m_axis_rxwrite_data_TREADY(axis_tcp2rxbuffer_tready),
.m_axis_rxwrite_data_TDATA(axis_tcp2rxbuffer_tdata),
.m_axis_rxwrite_data_TKEEP(axis_tcp2rxbuffer_tkeep),
.m_axis_rxwrite_data_TLAST(axis_tcp2rxbuffer_tlast),
`endif
// tx read commands
.m_axis_txread_cmd_TVALID(m_axis_read_cmd[ddrPortNetworkTx].valid),
.m_axis_txread_cmd_TREADY(m_axis_read_cmd[ddrPortNetworkTx].ready),
.m_axis_txread_cmd_TDATA(axis_read_cmd_data[ddrPortNetworkTx]),
//tx write commands
.m_axis_txwrite_cmd_TVALID(m_axis_write_cmd[ddrPortNetworkTx].valid),
.m_axis_txwrite_cmd_TREADY(m_axis_write_cmd[ddrPortNetworkTx].ready),
.m_axis_txwrite_cmd_TDATA(axis_write_cmd_data[ddrPortNetworkTx]),
// tx write status
.s_axis_txwrite_sts_TVALID(s_axis_write_sts[ddrPortNetworkTx].valid),
.s_axis_txwrite_sts_TREADY(s_axis_write_sts[ddrPortNetworkTx].ready),
.s_axis_txwrite_sts_TDATA(s_axis_write_sts[ddrPortNetworkTx].data),
// tx read path
.s_axis_txread_data_TVALID(axis_txread_data.valid),
.s_axis_txread_data_TREADY(axis_txread_data.ready),
.s_axis_txread_data_TDATA(axis_txread_data.data),
.s_axis_txread_data_TKEEP(axis_txread_data.keep),
.s_axis_txread_data_TLAST(axis_txread_data.last),
// tx write path
.m_axis_txwrite_data_TVALID(axis_txwrite_data.valid),
.m_axis_txwrite_data_TREADY(axis_txwrite_data.ready),
.m_axis_txwrite_data_TDATA(axis_txwrite_data.data),
.m_axis_txwrite_data_TKEEP(axis_txwrite_data.keep),
.m_axis_txwrite_data_TLAST(axis_txwrite_data.last),
/// SmartCAM I/F ///
.m_axis_session_upd_req_TVALID(upd_req_TVALID),
.m_axis_session_upd_req_TREADY(upd_req_TREADY),
.m_axis_session_upd_req_TDATA(upd_req_TDATA),

.s_axis_session_upd_rsp_TVALID(upd_rsp_TVALID),
.s_axis_session_upd_rsp_TREADY(upd_rsp_TREADY),
.s_axis_session_upd_rsp_TDATA(upd_rsp_TDATA),

.m_axis_session_lup_req_TVALID(lup_req_TVALID),
.m_axis_session_lup_req_TREADY(lup_req_TREADY),
.m_axis_session_lup_req_TDATA(lup_req_TDATA),
.s_axis_session_lup_rsp_TVALID(lup_rsp_TVALID),
.s_axis_session_lup_rsp_TREADY(lup_rsp_TREADY),
.s_axis_session_lup_rsp_TDATA(lup_rsp_TDATA),

/* Application Interface */
// listen&close port
.s_axis_listen_port_req_TVALID(s_axis_listen_port.valid),
.s_axis_listen_port_req_TREADY(s_axis_listen_port.ready),
.s_axis_listen_port_req_TDATA(s_axis_listen_port.data),
.m_axis_listen_port_rsp_TVALID(m_axis_listen_port_status.valid),
.m_axis_listen_port_rsp_TREADY(m_axis_listen_port_status.ready),
.m_axis_listen_port_rsp_TDATA(m_axis_listen_port_status.data),

// notification & read request
.m_axis_notification_TVALID(m_axis_notifications.valid),
.m_axis_notification_TREADY(m_axis_notifications.ready),
.m_axis_notification_TDATA(m_axis_notifications.data),
.s_axis_rx_data_req_TVALID(s_axis_read_package.valid),
.s_axis_rx_data_req_TREADY(s_axis_read_package.ready),
.s_axis_rx_data_req_TDATA(s_axis_read_package.data),

// open&close connection
.s_axis_open_conn_req_TVALID(s_axis_open_connection.valid),
.s_axis_open_conn_req_TREADY(s_axis_open_connection.ready),
.s_axis_open_conn_req_TDATA(s_axis_open_connection.data),
.m_axis_open_conn_rsp_TVALID(m_axis_open_status.valid),
.m_axis_open_conn_rsp_TREADY(m_axis_open_status.ready),
.m_axis_open_conn_rsp_TDATA(m_axis_open_status.data),
.s_axis_close_conn_req_TVALID(s_axis_close_connection.valid),
.s_axis_close_conn_req_TREADY(s_axis_close_connection.ready),
.s_axis_close_conn_req_TDATA(s_axis_close_connection.data),

// rx data
.m_axis_rx_data_rsp_metadata_TVALID(m_axis_rx_metadata.valid),
.m_axis_rx_data_rsp_metadata_TREADY(m_axis_rx_metadata.ready),
.m_axis_rx_data_rsp_metadata_TDATA(m_axis_rx_metadata.data),
.m_axis_rx_data_rsp_TVALID(m_axis_rx_data.valid),
.m_axis_rx_data_rsp_TREADY(m_axis_rx_data.ready),
.m_axis_rx_data_rsp_TDATA(m_axis_rx_data.data),
.m_axis_rx_data_rsp_TKEEP(m_axis_rx_data.keep),
.m_axis_rx_data_rsp_TLAST(m_axis_rx_data.last),

// tx data
.s_axis_tx_data_req_metadata_TVALID(s_axis_tx_metadata.valid),
.s_axis_tx_data_req_metadata_TREADY(s_axis_tx_metadata.ready),
.s_axis_tx_data_req_metadata_TDATA(s_axis_tx_metadata.data),
.s_axis_tx_data_req_TVALID(s_axis_tx_data.valid),
.s_axis_tx_data_req_TREADY(s_axis_tx_data.ready),
.s_axis_tx_data_req_TDATA(s_axis_tx_data.data),
.s_axis_tx_data_req_TKEEP(s_axis_tx_data.keep),
.s_axis_tx_data_req_TLAST(s_axis_tx_data.last),
.m_axis_tx_data_rsp_TVALID(m_axis_tx_status.valid),
.m_axis_tx_data_rsp_TREADY(m_axis_tx_status.ready),
.m_axis_tx_data_rsp_TDATA(m_axis_tx_status.data),

.myIpAddress_V(local_ip_address),
.regSessionCount_V(session_count_data),
.regSessionCount_V_ap_vld(session_count_valid),
`ifdef RX_DDR_BYPASS
//for external RX Buffer
.axis_data_count_V(rx_buffer_data_count),
.axis_max_data_count_V(32'd2048),
`endif
.aclk(net_clk),                                                        // input aclk
.aresetn(net_aresetn)                                                   // input aresetn
);

`ifdef RX_DDR_BYPASS
//RX BUFFER FIFO
axis_data_fifo_64_d2048 rx_buffer_fifo (
  .s_axis_aresetn(net_aresetn),          // input wire s_axis_aresetn
  .s_axis_aclk(net_clk),                // input wire s_axis_aclk
  .s_axis_tvalid(axis_tcp2rxbuffer_tvalid),
  .s_axis_tready(axis_tcp2rxbuffer_tready),
  .s_axis_tdata(axis_tcp2rxbuffer_tdata),
  .s_axis_tkeep(axis_tcp2rxbuffer_tkeep),
  .s_axis_tlast(axis_tcp2rxbuffer_tlast),
  .m_axis_tvalid(axis_rxbuffer2app_tvalid),
  .m_axis_tready(axis_rxbuffer2app_tready),
  .m_axis_tdata(axis_rxbuffer2app_tdata),
  .m_axis_tkeep(axis_rxbuffer2app_tkeep),
  .m_axis_tlast(axis_rxbuffer2app_tlast),
  .axis_data_count(rx_buffer_data_count[11:0])
);
assign rx_buffer_data_count[31:12] = 20'h0;
`endif

SmartCamCtl SmartCamCtl_inst
(
.clk(net_clk),
.rst(~net_aresetn),
.led0(),//(sc_led0),
.led1(),//(sc_led1),
.cam_ready(),//(cam_ready),

.lup_req_valid(lup_req_TVALID),
.lup_req_ready(lup_req_TREADY),
.lup_req_din(lup_req_TDATA),

.lup_rsp_valid(lup_rsp_TVALID),
.lup_rsp_ready(lup_rsp_TREADY),
.lup_rsp_dout(lup_rsp_TDATA),

.upd_req_valid(upd_req_TVALID),
.upd_req_ready(upd_req_TREADY),
.upd_req_din(upd_req_TDATA),

.upd_rsp_valid(upd_rsp_TVALID),
.upd_rsp_ready(upd_rsp_TREADY),
.upd_rsp_dout(upd_rsp_TDATA),

.debug()
);


if (WIDTH==64) begin
//TCP Data Path
`ifndef RX_DDR_BYPASS
axis_512_to_64_converter tcp_rxread_data_converter (
  .aclk(net_clk),                    // input wire aclk
  .aresetn(net_aresetn),              // input wire aresetn
  .s_axis_tvalid(s_axis_read_data[ddrPortNetworkRx].valid),  // input wire s_axis_tvalid
  .s_axis_tready(s_axis_read_data[ddrPortNetworkRx].ready),  // output wire s_axis_tready
  .s_axis_tdata(s_axis_read_data[ddrPortNetworkRx].data),    // input wire [63 : 0] s_axis_tdata
  .s_axis_tkeep(s_axis_read_data[ddrPortNetworkRx].keep),    // input wire [7 : 0] s_axis_tkeep
  .s_axis_tlast(s_axis_read_data[ddrPortNetworkRx].last),    // input wire s_axis_tlast
  .m_axis_tvalid(axis_rxread_data.valid),  // output wire m_axis_tvalid
  .m_axis_tready(axis_rxread_data.ready),  // input wire m_axis_tready
  .m_axis_tdata(axis_rxread_data.data),    // output wire [511 : 0] m_axis_tdata
  .m_axis_tkeep(axis_rxread_data.keep),    // output wire [63 : 0] m_axis_tkeep
  .m_axis_tlast(axis_rxread_data.last)    // output wire m_axis_tlast
);

axis_64_to_512_converter tcp_rxwrite_data_converter (
  .aclk(net_clk),                    // input wire aclk
  .aresetn(net_aresetn),              // input wire aresetn
  .s_axis_tvalid(axis_rxwrite_data.valid),  // input wire s_axis_tvalid
  .s_axis_tready(axis_rxwrite_data.ready),  // output wire s_axis_tready
  .s_axis_tdata(axis_rxwrite_data.data),    // input wire [63 : 0] s_axis_tdata
  .s_axis_tkeep(axis_rxwrite_data.keep),    // input wire [7 : 0] s_axis_tkeep
  .s_axis_tlast(axis_rxwrite_data.last),    // input wire s_axis_tlast
  .s_axis_tdest(1'b0),    // input wire s_axis_tlast
  .m_axis_tvalid(m_axis_write_data[ddrPortNetworkRx].valid),  // output wire m_axis_tvalid
  .m_axis_tready(m_axis_write_data[ddrPortNetworkRx].ready),  // input wire m_axis_tready
  .m_axis_tdata(m_axis_write_data[ddrPortNetworkRx].data),    // output wire [511 : 0] m_axis_tdata
  .m_axis_tkeep(m_axis_write_data[ddrPortNetworkRx].keep),    // output wire [63 : 0] m_axis_tkeep
  .m_axis_tlast(m_axis_write_data[ddrPortNetworkRx].last),    // output wire m_axis_tlast
  .m_axis_tdest()    // output wire m_axis_tlast
);
`endif
axis_512_to_64_converter tcp_txread_data_converter (
  .aclk(net_clk),                    // input wire aclk
  .aresetn(net_aresetn),              // input wire aresetn
  .s_axis_tvalid(s_axis_read_data[ddrPortNetworkTx].valid),  // input wire s_axis_tvalid
  .s_axis_tready(s_axis_read_data[ddrPortNetworkTx].ready),  // output wire s_axis_tready
  .s_axis_tdata(s_axis_read_data[ddrPortNetworkTx].data),    // input wire [63 : 0] s_axis_tdata
  .s_axis_tkeep(s_axis_read_data[ddrPortNetworkTx].keep),    // input wire [7 : 0] s_axis_tkeep
  .s_axis_tlast(s_axis_read_data[ddrPortNetworkTx].last),    // input wire s_axis_tlast
  .m_axis_tvalid(axis_txread_data.valid),  // output wire m_axis_tvalid
  .m_axis_tready(axis_txread_data.ready),  // input wire m_axis_tready
  .m_axis_tdata(axis_txread_data.data),    // output wire [511 : 0] m_axis_tdata
  .m_axis_tkeep(axis_txread_data.keep),    // output wire [63 : 0] m_axis_tkeep
  .m_axis_tlast(axis_txread_data.last)    // output wire m_axis_tlast
);

axis_64_to_512_converter tcp_txwrite_data_converter (
  .aclk(net_clk),                    // input wire aclk
  .aresetn(net_aresetn),              // input wire aresetn
  .s_axis_tvalid(axis_txwrite_data.valid),  // input wire s_axis_tvalid
  .s_axis_tready(axis_txwrite_data.ready),  // output wire s_axis_tready
  .s_axis_tdata(axis_txwrite_data.data),    // input wire [63 : 0] s_axis_tdata
  .s_axis_tkeep(axis_txwrite_data.keep),    // input wire [7 : 0] s_axis_tkeep
  .s_axis_tlast(axis_txwrite_data.last),    // input wire s_axis_tlast
  .s_axis_tdest(1'b0),    // input wire s_axis_tlast
  .m_axis_tvalid(m_axis_write_data[ddrPortNetworkTx].valid),  // output wire m_axis_tvalid
  .m_axis_tready(m_axis_write_data[ddrPortNetworkTx].ready),  // input wire m_axis_tready
  .m_axis_tdata(m_axis_write_data[ddrPortNetworkTx].data),    // output wire [511 : 0] m_axis_tdata
  .m_axis_tkeep(m_axis_write_data[ddrPortNetworkTx].keep),    // output wire [63 : 0] m_axis_tkeep
  .m_axis_tlast(m_axis_write_data[ddrPortNetworkTx].last),    // output wire m_axis_tlast
  .m_axis_tdest()    // output wire m_axis_tlast
);
end

if (WIDTH==512) begin
//TCP Data Path
assign axis_rxread_data.valid = s_axis_txread_data.valid;
assign s_axis_rxread_data.ready = axis_txread_data.ready;
assign axis_rxread_data.data = s_axis_txread_data.data;
assign axis_rxread_data.keep = s_axis_txread_data.keep;
assign axis_rxread_data.last = s_axis_txread_data.last;

assign m_axis_rxwrite_data.valid = axis_txwrite_data.valid;
assign axis_rxwrite_data.ready = m_axis_txwrite_data.ready;
assign m_axis_rxwrite_data.data = axis_txwrite_data.data;
assign m_axis_rxwrite_data.keep = axis_txwrite_data.keep;
assign m_axis_rxwrite_data.last = axis_txwrite_data.last;

assign axis_txread_data.valid = s_axis_txread_data.valid;
assign s_axis_txread_data.ready = axis_txread_data.ready;
assign axis_txread_data.data = s_axis_txread_data.data;
assign axis_txread_data.keep = s_axis_txread_data.keep;
assign axis_txread_data.last = s_axis_txread_data.last;

assign m_axis_txwrite_data.valid = axis_txwrite_data.valid;
assign axis_txwrite_data.ready = m_axis_txwrite_data.ready;
assign m_axis_txwrite_data.data = axis_txwrite_data.data;
assign m_axis_txwrite_data.keep = axis_txwrite_data.keep;
assign m_axis_txwrite_data.last = axis_txwrite_data.last;
end


end
else begin
assign s_axis_rx_data.ready = 1'b1;
assign m_axis_tx_data.valid = 1'b0;

//assign s_axis_tx_meta.ready = 1'b0;
//assign s_axis_tx_data.ready = 1'b0;

assign m_axis_mem_write_cmd[0].valid = 1'b0;
assign m_axis_mem_read_cmd[0].valid = 1'b0;
assign s_axis_mem_write_sts[0].ready = 1'b0;
assign s_axis_mem_write_sts[0].ready = 1'b0;
assign m_axis_mem_write_data[0].valid = 1'b0;
assign s_axis_mem_read_data[0].ready = 1'b0;

assign m_axis_mem_write_cmd[1].valid = 1'b0;
assign m_axis_mem_read_cmd[1].valid = 1'b0;
assign s_axis_mem_write_sts[1].ready = 1'b0;
assign s_axis_mem_write_sts[1].ready = 1'b0;
assign m_axis_mem_write_data[1].valid = 1'b0;
assign s_axis_mem_read_data[1].ready = 1'b0;

assign s_axis_listen_port.ready = 1'b0;
assign m_axis_listen_port_status.valid = 1'b0;

assign s_axis_open_connection.ready = 1'b0;
assign m_axis_open_status.valid = 1'b0;
assign s_axis_close_connection.ready = 1'b0;

assign m_axis_notifications.valid = 1'b0;
assign s_axis_read_package.ready = 1'b0;

assign m_axis_rx_metadata.valid = 1'b0;
assign m_axis_rx_data.valid = 1'b0;

assign s_axis_tx_metadata.ready = 1'b0;
assign s_axis_tx_data.ready = 1'b0;
assign m_axis_tx_status.valid = 1'b0;

assign session_count_valid = 1'b0;

end
endgenerate

endmodule

`default_nettype wire