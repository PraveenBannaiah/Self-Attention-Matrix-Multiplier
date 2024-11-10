`include "common.vh"

module MyDesign(
//---------------------------------------------------------------------------
//System signals
  input wire reset_n                      ,  
  input wire clk                          ,

//---------------------------------------------------------------------------
//Control signals
  input wire dut_valid                    , 
  output wire dut_ready                   ,

//---------------------------------------------------------------------------
//input SRAM interface
  output wire                           dut__tb__sram_input_write_enable  ,
  output wire [`SRAM_ADDR_RANGE     ]   dut__tb__sram_input_write_address ,
  output wire [`SRAM_DATA_RANGE     ]   dut__tb__sram_input_write_data    ,
  output wire [`SRAM_ADDR_RANGE     ]   dut__tb__sram_input_read_address  , 
  input  wire [`SRAM_DATA_RANGE     ]   tb__dut__sram_input_read_data     ,     

//weight SRAM interface
  output wire                           dut__tb__sram_weight_write_enable  ,
  output wire [`SRAM_ADDR_RANGE     ]   dut__tb__sram_weight_write_address ,
  output wire [`SRAM_DATA_RANGE     ]   dut__tb__sram_weight_write_data    ,
  output wire [`SRAM_ADDR_RANGE     ]   dut__tb__sram_weight_read_address  , 
  input  wire [`SRAM_DATA_RANGE     ]   tb__dut__sram_weight_read_data     ,     

//result SRAM interface
  output wire                           dut__tb__sram_result_write_enable  ,
  output wire [`SRAM_ADDR_RANGE     ]   dut__tb__sram_result_write_address ,
  output wire [`SRAM_DATA_RANGE     ]   dut__tb__sram_result_write_data    ,
  output wire [`SRAM_ADDR_RANGE     ]   dut__tb__sram_result_read_address  , 
  input  wire [`SRAM_DATA_RANGE     ]   tb__dut__sram_result_read_data     ,

//scratchpad SRAM interface

  output wire                           dut__tb__sram_scratchpad_write_enable  ,
  output wire [`SRAM_ADDR_RANGE     ]   dut__tb__sram_scratchpad_write_address ,
  output wire [`SRAM_DATA_RANGE     ]   dut__tb__sram_scratchpad_write_data    ,
  output wire [`SRAM_ADDR_RANGE     ]   dut__tb__sram_scratchpad_read_address  , 
  input  wire [`SRAM_DATA_RANGE     ]   tb__dut__sram_scratchpad_read_data     

);

//Making register copies
  reg  [`SRAM_ADDR_RANGE     ]   reg_dut__tb__sram_input_read_address; 
 // reg  [`SRAM_DATA_RANGE     ]   reg_tb__dut__sram_input_read_data;               //Because at this point i don't think i want to store the retrieved values

  reg  [`SRAM_ADDR_RANGE     ]   reg_dut__tb__sram_weight_read_address; 
 // reg  [`SRAM_DATA_RANGE     ]   reg_tb__dut__sram_weight_read_data;     

  reg                            reg_dut__tb__sram_result_write_enable;
  reg  [`SRAM_ADDR_RANGE     ]   reg_dut__tb__sram_result_write_address;
  reg  [`SRAM_DATA_RANGE     ]   reg_dut__tb__sram_result_write_data;
  reg  [`SRAM_DATA_RANGE     ]   reg_dut__tb__sram_result_read_address;
//  reg  [`SRAM_DATA_RANGE     ]   reg_dut__tb__sram_result_read_data;
  
  reg                            reg_dut__tb__sram_scratchpad_write_enable;
  reg  [`SRAM_ADDR_RANGE     ]   reg_dut__tb__sram_scratchpad_write_address;
  reg  [`SRAM_DATA_RANGE     ]   reg_dut__tb__sram_scratchpad_write_data;
  reg  [`SRAM_DATA_RANGE     ]   reg_dut__tb__sram_scratchpad_read_address;
//  reg  [`SRAM_DATA_RANGE     ]   reg_dut__tb__sram_scratchpad_read_data;
  
  
  assign dut__tb__sram_input_write_enable = 0;                                //Because we won't be writing to sramA and sramB
  assign dut__tb__sram_weight_write_enable = 0;
  
  assign dut__tb__sram_input_read_address = reg_dut__tb__sram_input_read_address;
  assign dut__tb__sram_weight_read_address = reg_dut__tb__sram_weight_read_address;
  assign dut__tb__sram_result_write_enable = reg_dut__tb__sram_result_write_enable;
  assign dut__tb__sram_result_write_address = reg_dut__tb__sram_result_write_address;
  assign dut__tb__sram_result_write_data = reg_dut__tb__sram_result_write_data;
  assign dut__tb__sram_result_read_address = reg_dut__tb__sram_result_read_address;
  assign dut__tb__sram_scratchpad_write_enable = reg_dut__tb__sram_scratchpad_write_enable;
  assign dut__tb__sram_scratchpad_write_address = reg_dut__tb__sram_scratchpad_write_address;
  assign dut__tb__sram_scratchpad_write_data = reg_dut__tb__sram_scratchpad_write_data;
  assign dut__tb__sram_scratchpad_read_address = reg_dut__tb__sram_scratchpad_read_address;
  
  
  parameter [3:0] 
   S0 = 4'b0000,
   S1 = 4'b0001,
   S2 = 4'b0010,
   S3 = 4'b0011,
   S4 = 4'b0100,
   S5 = 4'b0101,
   S6 = 4'b0110,
   S7 = 4'b0111,
   S8 = 4'b1000,
   S9 = 4'b1001,
   S10 = 4'b1010,
   S11 = 4'b1011,
   S12 = 4'b1100,
   S13 = 4'b1101,
   S14 = 4'b1110,
   S15 = 4'b1111;
   
  reg [3:0] current_state, next_state;
  reg [15:0] rows_A, columns_A, rows_B, columns_B;
  reg [15:0] Arow_tracker, Bcolumn_tracker;
  reg dut_ready_temp;
  reg [31:0] sramA_pointer, sramB_pointer, sramC_pointer, sramC_read_pointer, scratchpad_pointer ;
  reg [31:0] first_address_of_a_row;
  reg [31:0] first_address_of_a_matrix_in_B;
  reg write_flag, write_flag_stage2;
  reg finish_flag;
  reg pointer_update_flag, pointer_update_flag_stage2;
  reg help_flag;
  reg [15:0] sramA_column_counter;
  
  reg [2:0] QKV_counter;
  reg [31:0] accum_result;
  reg [31:00] temp_accum_result;
  
  reg [31:0] first_address_of_V;
  reg [31:0] first_address_of_S;
  
  assign dut_ready = dut_ready_temp;
  
  always@(posedge clk)
  if(!reset_n)
	current_state <= S0;
  else
    current_state <= next_state;
	
	
  always@(*)
  begin
    case(current_state)
		S0: begin                               //RESET and IDLE block 
			reg_dut__tb__sram_result_write_enable = 1'b0;
			reg_dut__tb__sram_scratchpad_write_enable = 1'b0;
		    if((dut_valid)&&(reset_n))
			begin
				next_state = S1;
				dut_ready_temp = 1'b0;
			end
			else
			begin
				next_state = S0;
				dut_ready_temp = 1'b1;
			end
			end
			
		S1: begin                                            //Request for dimensions 
			reg_dut__tb__sram_input_read_address = 1'b0;
			reg_dut__tb__sram_weight_read_address = 1'b0;
			next_state = S2;
			end
			
			  
		S2: begin                                                  
			reg_dut__tb__sram_input_read_address = 1'b1;           //Get dimensions and request for the first elements      
			reg_dut__tb__sram_weight_read_address = 1'b1;
			next_state = S3;
			end
			
		S3: begin                                                   //The state we loop around at the time of data collection 
			reg_dut__tb__sram_result_write_enable = 1'b0;
			reg_dut__tb__sram_scratchpad_write_enable = 1'b0;
			reg_dut__tb__sram_input_read_address = sramA_pointer;
			reg_dut__tb__sram_weight_read_address = sramB_pointer;
			if((sramA_column_counter+1) > columns_A)
			begin
				next_state = S8;
				pointer_update_flag = 1'b1;
			end
			else
			begin
				next_state = S3;
				pointer_update_flag = 1'b1;
				
			end
			end
			  
		S8: begin                                                                //We get the last data of a particular computation here
			next_state = S4;
			pointer_update_flag = 1'b1;
			reg_dut__tb__sram_result_write_enable = 1'b0;
			reg_dut__tb__sram_scratchpad_write_enable = 1'b0;
			reg_dut__tb__sram_input_read_address = sramA_pointer;
			reg_dut__tb__sram_weight_read_address = sramB_pointer;
			end
		
			
		S4: begin
			reg_dut__tb__sram_input_read_address = sramA_pointer;
			reg_dut__tb__sram_weight_read_address = sramB_pointer;
			reg_dut__tb__sram_result_write_address = sramC_pointer;
			reg_dut__tb__sram_result_write_data = accum_result;
			reg_dut__tb__sram_result_write_enable = 1'b1;
			
			//writing to scratchpad SRAM
			if(QKV_counter > 1'b1)
			begin
				reg_dut__tb__sram_scratchpad_write_address = scratchpad_pointer;
				reg_dut__tb__sram_scratchpad_write_data = accum_result;
				reg_dut__tb__sram_scratchpad_write_enable = 1'b1;
			end
			
			
			if((Arow_tracker+1) > rows_A)
			begin
				if(QKV_counter <= 2'b11)
				begin
					next_state = S3;
					pointer_update_flag = 1'b1;
					dut_ready_temp = 1'b0;
				end
				else
				begin
					next_state = S6;
					pointer_update_flag = 1'b0;
					dut_ready_temp = 1'b0;
				end
			end
			else if ((Bcolumn_tracker+1) > columns_B)
				begin
				next_state = S5;
				pointer_update_flag = 1'b1;
				dut_ready_temp = 1'b0;
				end
				
			else 
			begin
				next_state = S3;
				pointer_update_flag = 1'b1;
				dut_ready_temp = 1'b0;
			end
			end
			
		S5: begin
			reg_dut__tb__sram_input_read_address = sramA_pointer;
			reg_dut__tb__sram_weight_read_address = sramB_pointer;
			pointer_update_flag = 1'b1;
			reg_dut__tb__sram_result_write_enable = 1'b0;
			next_state = S3;
			end
			
			
		S6: begin
			next_state = S7;
			reg_dut__tb__sram_result_write_enable = 1'b0;
			reg_dut__tb__sram_scratchpad_write_enable = 1'b0;
			end
			
		S7: begin
			reg_dut__tb__sram_result_write_enable = 1'b0;
			reg_dut__tb__sram_scratchpad_write_enable = 1'b0;
			reg_dut__tb__sram_scratchpad_read_address = sramB_pointer;
			reg_dut__tb__sram_result_read_address = sramA_pointer;
			
			if(sramA_column_counter == columns_A)
			begin
				next_state = S9;
				pointer_update_flag_stage2 = 1'b0;
			end
			else
			begin
				next_state = S7;
				pointer_update_flag_stage2 = 1'b1;
			end
			
			end
			
		S9:  begin
			next_state = S10;
			pointer_update_flag_stage2 = 1'b1;
			reg_dut__tb__sram_scratchpad_write_enable = 1'b0;
			reg_dut__tb__sram_scratchpad_read_address = 1'bx;
			reg_dut__tb__sram_result_read_address = 1'bx;
			
			reg_dut__tb__sram_scratchpad_write_enable = 1'b0;
			reg_dut__tb__sram_result_write_enable = 1'b0; 
			end
			
		S10: begin
			reg_dut__tb__sram_scratchpad_write_enable = 1'b0;
			
			pointer_update_flag_stage2 = 1'b1;
			
			reg_dut__tb__sram_result_write_address = sramC_pointer;
			reg_dut__tb__sram_result_write_data = accum_result;
			reg_dut__tb__sram_result_write_enable = 1'b1;
			
			reg_dut__tb__sram_result_read_address = sramA_pointer;
			reg_dut__tb__sram_scratchpad_read_address = sramB_pointer;
			
			if((Arow_tracker > rows_A))
			begin
				next_state = S11;                                //Go to stage 3
				pointer_update_flag_stage2 = 1'b0;
				dut_ready_temp = 1'b0;
			end
			
			else
				next_state = S7;
			end
			
		S11:begin
			reg_dut__tb__sram_result_read_address = first_address_of_V;          //Read first value of V
			reg_dut__tb__sram_result_write_enable = 1'b0;
			reg_dut__tb__sram_scratchpad_write_enable = 1'b0;
			next_state = S12;
			end
		
		S12:begin
			reg_dut__tb__sram_scratchpad_write_enable = 1'b0;
			
			reg_dut__tb__sram_scratchpad_write_address = scratchpad_pointer;
			reg_dut__tb__sram_scratchpad_write_data = tb__dut__sram_result_read_data;
			reg_dut__tb__sram_scratchpad_write_enable = 1'b1;
			
			reg_dut__tb__sram_result_read_address = sramC_pointer;
			
			if(Bcolumn_tracker <= columns_A)
				next_state = S12;
			else
				next_state = 0;
			
			end
			
		S13:begin
			reg_dut__tb__sram_result_write_enable = 1'b0;
			reg_dut__tb__sram_scratchpad_write_enable = 1'b0;
			next_state = S0;
			end
			
			
		default: begin
			next_state = S0;
			end
			
	endcase
end
			
always@(posedge clk)
begin 
	//Resetting all the F/Fs 
	if(current_state == S0)
	begin 
		Arow_tracker <= 1'b1;
		Bcolumn_tracker <= 1'b1;
		sramA_pointer <= 2'b10;
		sramB_pointer <= 2'b10;
		sramC_pointer <= 1'b0;
		first_address_of_a_row <= 1'b1;
		sramA_column_counter<= 2'b10;
		accum_result <= 1'b0;
		pointer_update_flag <= 1'b0;
		temp_accum_result <= 1'b0;
		QKV_counter <= 1'b1;
		first_address_of_a_matrix_in_B <= 1'b1;
		scratchpad_pointer <= 1'b0;
		first_address_of_V <= 1'b0; 
	end
	
	//Assigning the dimensions to flip flops
	if(current_state == S2)
	begin
	rows_A <= tb__dut__sram_input_read_data[31:16];
	columns_A <= tb__dut__sram_input_read_data[15:0];
	rows_B <= tb__dut__sram_weight_read_data[31:16];
	columns_B <= tb__dut__sram_weight_read_data[15:0];
	end	
	
	//Performing multiplication 
	if((current_state == S3)|| (current_state == S8) || (current_state == S5))
	begin
		accum_result <= accum_result + tb__dut__sram_input_read_data * tb__dut__sram_weight_read_data;
	end
	
	//Updating SRAMC pointers
	if (current_state == S4)
	begin
	accum_result <= tb__dut__sram_input_read_data * tb__dut__sram_weight_read_data;
	sramC_pointer <= sramC_pointer + 1;
	if(QKV_counter > 1'b1)
		scratchpad_pointer <= scratchpad_pointer + 1;
	if((QKV_counter > 2'b10) && (first_address_of_V == 1'b0))
		first_address_of_V <= sramC_pointer + 1;
	
	
	//accum_result <= 1'b0;
	end
	
	//Updating the matrixA and matrixB counters
	if(pointer_update_flag == 1'b1)
	begin 
		if ((sramA_column_counter+1) <= columns_A)
		begin
			sramA_pointer <= sramA_pointer + 1;
			sramB_pointer <= sramB_pointer + 1;
			sramA_column_counter <= sramA_column_counter + 1;
		end
		else
		begin 
			sramA_column_counter <= 1'b1;
			if((Bcolumn_tracker+1) <= columns_B)
			begin 
				Bcolumn_tracker <= Bcolumn_tracker + 1;
				sramA_pointer <= first_address_of_a_row;
				sramB_pointer <= sramB_pointer + 1;				
			end
			else
			begin
				Bcolumn_tracker <= 1'b1;
				if ((Arow_tracker+1) <= rows_A)
				begin
				Arow_tracker <= Arow_tracker + 1;
				sramA_pointer <= sramA_pointer + 1;
				sramB_pointer <= first_address_of_a_matrix_in_B;
				first_address_of_a_row <= sramA_pointer + 1;
				end
				else
				begin
					if(QKV_counter <= 2'b11)
					begin
						sramB_pointer <= sramB_pointer + 1;
						first_address_of_a_matrix_in_B <= sramB_pointer + 1;
						sramA_pointer <= 1'b1;
						first_address_of_a_row <= 1'b1;
						QKV_counter <= QKV_counter + 1;
						if(QKV_counter < 2'b11)
							Arow_tracker <= 1'b1;
					end
				end
			end
		end
	end
	
	
	
	//Stage 2
	if(current_state == S6)                                             //Initialise the values for the second stage
	begin 
		Arow_tracker <= 1'b1;
		Bcolumn_tracker <= 1'b1;
		sramA_pointer <= 1'b0;
		sramB_pointer <= 1'b1;
		//scratchpad_pointer <= 1'b1;
		first_address_of_a_row <= 1'b0;
		sramA_column_counter<= 1'b1;
		accum_result <= 1'b0;
		pointer_update_flag <= 1'b0;
		pointer_update_flag_stage2 <= 1'b0;
		temp_accum_result <= 1'b0;
		//first_address_of_a_matrix_in_B <= 1'b0;
		rows_B <= columns_B;                                           //Both matrices are similar 
		columns_A <= columns_B;
		columns_B <= rows_A;
		QKV_counter <= 1'b0;
		
	end
	
	//Performing multiplication 
	if((current_state == S7)||(current_state == S9))
	begin
		if((reg_dut__tb__sram_result_read_address == 1'b0)&&(current_state == S7))
			accum_result <= 1'b0;
		else
			accum_result <= accum_result + tb__dut__sram_result_read_data * tb__dut__sram_scratchpad_read_data;
	end
	
	//Resetting accum register
	if(current_state == S10)
	begin
		accum_result <= 1'b0;
		sramC_pointer <= sramC_pointer + 1;
	end
		
	//Updating the matrixA and matrixB counters
	if(pointer_update_flag_stage2 == 1'b1)
	begin
		if(sramA_column_counter < columns_A)
		begin
			sramA_pointer <= sramA_pointer + 1;
			sramB_pointer <= sramB_pointer + 1;
			sramA_column_counter <= sramA_column_counter + 1;
		end
		
		else
		begin
			sramA_column_counter <= 1;
			if(Bcolumn_tracker < columns_B)
			begin
				Bcolumn_tracker <= Bcolumn_tracker + 1;
				sramA_pointer <= first_address_of_a_row;
				sramB_pointer <= sramB_pointer + 1;
			end
			else
			begin
				if(Arow_tracker <= rows_A)
				begin
					Bcolumn_tracker <= 1'b1;
					Arow_tracker <= Arow_tracker + 1;
					sramA_pointer <= sramA_pointer + 1;
					sramB_pointer <= 1'b1;
					first_address_of_a_row <= sramA_pointer + 1;
				end
			end
		end
	end
	
	
	//Stage 3
	if(current_state == S11)
	begin
		sramC_pointer <= first_address_of_V + columns_A;
		scratchpad_pointer <= 1'b0;
		Arow_tracker <= 2'b10;
		Bcolumn_tracker <= 1'b1;
	end
	
	else if(current_state == S12)
	begin
		if(Arow_tracker < rows_A)
		begin
			Arow_tracker <= Arow_tracker + 1;
			sramC_pointer <= sramC_pointer + columns_A;           //I can't use column B because it was modified in the last stage
			scratchpad_pointer <= scratchpad_pointer + 1;
		end
		else
		begin
			if(Bcolumn_tracker <= columns_A)                       //Because Columns B updates in S writing stage to rows A
			begin
			Bcolumn_tracker <= Bcolumn_tracker + 1;
			Arow_tracker <= 1;
			first_address_of_V <= first_address_of_V + 1;
			sramC_pointer <= first_address_of_V + 1;
			scratchpad_pointer <= scratchpad_pointer + 1;
			end
		end
	end
					
				
 end
  
  
 endmodule