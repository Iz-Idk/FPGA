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
		clk: 					IN 	std_logic; --50MHz in our board
		R_switch, G_switch, B_switch:	IN		std_logic;
		H_sync, V_sync: 	OUT	std_logic;
		BLANKn, SYNCn : 	OUT 	std_logic;
		R, G, B: 			OUT 	std_logic_vector(3 DOWNTO 0)
	);
END vga_interface;

ARCHITECTURE rtl OF vga_interface IS

	SIGNAL Hsync, Vsync, Hactive, Vactive, dena, clk_vga:	std_logic;

BEGIN
-------------------------------------------------------
--Part 1: CONTROL GENERATOR
-------------------------------------------------------		
		--Static signals for DACs:
		BLANKn 	<= '1'; --no direct blanking
		SYNCn 	<= '0'; --no sync on green
		
		--Create pixel clock (50MHz->25MHz):
		PROCESS( clk )
		BEGIN
			IF rising_edge( clk ) THEN 
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
	
		H_sync <= Hsync;
		V_sync <= Vsync;
	
		---Display enable generation:
		dena <= Hactive and Vactive;
	
-------------------------------------------------------
--Part 2: IMAGE GENERATOR
-------------------------------------------------------	
	PROCESS( Hsync, Vactive, dena, R_switch, G_switch, B_switch )
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
					R <= ( OTHERS => '0' );
					G <= ( OTHERS => '0' );
					B <= ( OTHERS => '0' );
				WHEN 1 | 80 | 160 | 240 => 
					R <= ( OTHERS => '1' );
					G <= ( OTHERS => '1' );
					B <= ( OTHERS => '1' );
				WHEN 2 TO 79 =>
					R <= ( OTHERS => '1' );
					G <= ( OTHERS => '0' );
					B <= ( OTHERS => '0' );
				WHEN 81 TO 159 =>
					R <= ( OTHERS => '0' );
					G <= ( OTHERS => '1' );
					B <= ( OTHERS => '0' );
				WHEN 161 TO 239 =>
					R <= ( OTHERS => '0' );
					G <= ( OTHERS => '0' );
					B <= ( OTHERS => '1' );
				WHEN OTHERS =>
					R <= ( OTHERS => R_switch );
					G <= ( OTHERS => G_switch );
					B <= ( OTHERS => B_switch );
			END CASE;
			CASE line_count IS
				WHEN 234 TO 246 =>
					R <= ( OTHERS => '1' );
					G <= ( OTHERS => '0' );
					B <= ( OTHERS => '0' );
				WHEN OTHERS => 
					R <= ( OTHERS => '1' );
					G <= ( OTHERS => '1' );
					B <= ( OTHERS => '1' );
			END CASE;
		ELSE			
			R <= (OTHERS => '0');
			G <= (OTHERS => '0');
			B <= (OTHERS => '0');
		END IF;
	END PROCESS;	
	
END ARCHITECTURE;