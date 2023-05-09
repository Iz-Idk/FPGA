LIBRARY 	ieee;
USE 		ieee.std_logic_1164.all;
USE 		ieee.std_logic_arith.all;

ENTITY vga_interface IS
	GENERIC(
		H_LOW:	natural	:= 96; --Hpulse
		HBP: 		natural 	:= 48; --HBP
		H_HIGH:	natural 	:= 640; --Hactive
		HFP: 		natural  := 16; --HFP
		V_LOW: 	natural  := 2; --Vpulse
		VBP: 		natural	:= 33; --VBP
		V_HIGH: 	natural  := 480; --Vactive
		VFP: 		natural	:= 10 --VFP
	); 
	PORT(
		CLOCK_50: 					IN 	std_logic; --50MHz in our board
		SW : in std_logic_vector(9 downto 0);--R_switch, G_switch, B_switch:	IN		std_logic;
		VGA_HS, VGA_VS : out std_logic; --H_sync, V_sync: 	OUT	std_logic;
		BLANKn_5, SYNCn_5 : 	OUT 	std_logic;
		VGA_R, VGA_G, VGA_B: 			OUT 	std_logic_vector(3 DOWNTO 0)
	);
END vga_interface;

ARCHITECTURE rtl OF vga_interface IS

	SIGNAL Hsync, Vsync, Hactive, Vactive, dena, clk_vga:	std_logic;

BEGIN
-------------------------------------------------------
--Part 1: CONTROL GENERATOR
-------------------------------------------------------		
		--Static signals for DACs:
		BLANKn_5 	<= '1'; --no direct blanking
		SYNCn_5 	<= '0'; --no sync on green
		
		--Create pixel clock (50MHz->25MHz):
		PROCESS( clock_50 )
		BEGIN
			IF rising_edge( clock_50 ) THEN 
				clk_vga <= not clk_vga;
			END IF;
		END PROCESS;
	
		--Horizontal signals generation:
		PROCESS( clk_vga )
			VARIABLE Hcount:	natural RANGE 0 to H_LOW + HBP + H_HIGH + HFP;
		BEGIN
			IF rising_edge( clk_vga ) THEN 
				Hcount := Hcount + 1;
				IF Hcount = H_LOW THEN 
					Hsync 	<= '1';
				ELSIF Hcount = H_LOW + HBP THEN 
					Hactive 	<= '1';
				ELSIF Hcount = H_LOW + HBP + H_HIGH THEN 
					Hactive 	<= '0';
				ELSIF Hcount = H_LOW + HBP + H_HIGH + HFP THEN 
					Hsync 	<= '0'; 
					Hcount 	:=  0;
				END IF;
			END IF;
		END PROCESS;
		
		--Vertical signals generation:
		PROCESS( Hsync )
			VARIABLE Vcount:	natural RANGE 0 TO V_LOW + VBP + V_HIGH + VFP;
		BEGIN
			IF rising_edge( Hsync ) THEN 
				Vcount := Vcount + 1;
				IF Vcount = V_LOW THEN 
					Vsync 	<= '1';
				ELSIF Vcount = V_LOW + VBP THEN 
					Vactive 	<= '1';
				ELSIF Vcount = V_LOW + VBP + V_HIGH THEN 
					Vactive 	<= '0';
				ELSIF Vcount = V_LOW + VBP + V_HIGH + VFP THEN 
					Vsync 	<= '0'; 
					Vcount 	:=  0;
				END IF;
			END IF;
		END PROCESS;
	
		VGA_HS <= Hsync;
		VGA_VS <= Vsync;
	
		---Display enable generation:
		dena <= Hactive and Vactive;
	
-------------------------------------------------------
--Part 2: IMAGE GENERATOR
-------------------------------------------------------	
	PROCESS( Hsync, Vactive, dena, SW(0), SW(1), SW(2) )
		VARIABLE line_count:	natural RANGE 0 TO V_HIGH;
	BEGIN
		IF rising_edge( Hsync ) THEN
			IF Vactive = '1' THEN
				line_count := line_count + 1;
			ELSE
				line_count := 0;
			END IF;
		END IF;
		IF dena = '1' THEN
			CASE line_count IS
				WHEN 0 =>
				VGA_R <= ( OTHERS => '0' );
				VGA_G <= ( OTHERS => '0' );
				VGA_B <= ( OTHERS => '0' );
				WHEN 1 | 80 | 160 | 240 => 
					VGA_R <= ( OTHERS => '1' );
					VGA_G <= ( OTHERS => '1' );
					VGA_B <= ( OTHERS => '1' );
				WHEN 2 TO 79 =>
					VGA_R <= ( OTHERS => '1' );
					VGA_G <= ( OTHERS => '0' );
					VGA_B <= ( OTHERS => '0' );
				WHEN 81 TO 159 =>
					VGA_R <= ( OTHERS => '0' );
					VGA_G <= ( OTHERS => '1' );
					VGA_B <= ( OTHERS => '0' );
				WHEN 161 TO 239 =>
					VGA_R <= ( OTHERS => '0' );
					VGA_G <= ( OTHERS => '0' );
					VGA_B <= ( OTHERS => '1' );
				WHEN OTHERS =>
						VGA_R <= ( OTHERS => '0' );
					VGA_G <= ( OTHERS => '0' );
					VGA_B <= ( OTHERS => '0');
			END CASE;
		ELSE			
			VGA_R <= (OTHERS => '0');
			VGA_G <= (OTHERS => '0');
			VGA_B <= (OTHERS => '0');
		END IF;
	END PROCESS;	
	
END ARCHITECTURE;