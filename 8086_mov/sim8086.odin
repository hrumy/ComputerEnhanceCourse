package main  

import "core:fmt"
import "core:os"
import "core:time"

Register_W0 :: [8]string {
    "al",
    "cl",
    "dl",
    "bl",
    "ah",
    "ch",
    "dh",
    "bh",
}

Register_W1 :: [8]string {
    "ax",
    "cx",
    "dx",
    "bx",
    "sp",
    "bp",
    "si",
    "di",
}

effective_adress := [8]string {
    "bx + si",
    "bx + di",
    "bp + si",
    "bp + di",
    "si",
    "di",
    "bp",
    "bx",
}

main :: proc() {
    args := os.args[1:]

	if len(args) != 1 {
        fmt.println("File name required");
		return;
	}

    data, succes := os.read_entire_file_from_filename(args[0]);
    if !succes {
        fmt.println("Error reading file.");
        return;
    }

    fmt.printf("bits 16\n\n");
    for i := 0; i < len(data); i += 2 {
        first_byte  : u8 = data[i];
        second_byte : u8 = data[i + 1];

        src_bits, dst_bits : u8;

        switch first_byte {
            case 0b10001000..=0b10001011 : {
            // register/memory to/from register 

                d := bool((first_byte & 2) >> 1);
                w := bool( first_byte & 1);
                
                mod :=  second_byte >> 6;
                reg := (second_byte << 2) >> 5;
                rm  :=  second_byte & 7;

                reg_string := w ? Register_W1 : Register_W0;

                switch mod {
                    case 0b00 : {
                    // memory mode, no displacement
                        if rm == 0b110 {
                        // 16-bit displacement
                            offset  := u16(data[i + 3]);
                            offset   = offset << 8;
                            offset  |= u16(data[i + 2]);
                            if d { fmt.printf("mov %s, [%d]\n", reg_string[reg], offset); }
                            else { fmt.printf("mov [%d], %s\n", offset, reg_string[reg]); }
                            i += 2;
                        }
                        else {
                            if d { fmt.printf("mov %s, [%s]\n", reg_string[reg], effective_adress[rm]); }
                            else { fmt.printf("mov [%s], %s\n", effective_adress[rm], reg_string[reg]); }
                        }
                    }
                        
                    case 0b01 : {
                    // memory mode, 8-bit displacement
                        if d { fmt.printf("mov %s, [%s + %d]\n", reg_string[reg], effective_adress[rm], data[i + 2]); }
                        else { fmt.printf("mov [%s + %d], %s\n", effective_adress[rm], data[i + 2], reg_string[reg]); }
                        i += 1;
                    }

                    case 0b10 : {
                    // memory mode, 16-bit displacement
                        offset  := u16(data[i + 3]);
                        offset   = offset << 8;
                        offset  |= u16(data[i + 2]);
                        
                        if d { fmt.printf("mov %s, [%s + %d]\n", reg_string[reg], effective_adress[rm], offset); }
                        else { fmt.printf("mov [%s + %d], %s\n", effective_adress[rm], offset, reg_string[reg]); }
                        
                        i += 2;
                    }

                    case 0b11 : {
                    // register mode
                        if d {
                            dst_bits = reg;
                            src_bits = rm;
                        }
                        else {
                            src_bits = reg;
                            dst_bits = rm;
                        }
        
                        src := reg_string[src_bits];
                        dst := reg_string[dst_bits];
        
                        fmt.printf("mov %s, %s\n", dst, src); 
                    }
                }
            }

            case 0b10110000..=0b10111111 : {
            // immediate to register

                w   := bool((first_byte & 8) >> 3);
                reg := first_byte & 7;

                reg_string := w ? Register_W1 : Register_W0;
                
                data_in : u16;
                if w {
                    data_in  = u16(data[i + 2]);
                    data_in  = data_in << 8;
                    data_in |= u16(second_byte);

                    i += 1;
                }
                else {
                    data_in = u16(second_byte);
                }
                
                fmt.printf("mov %s, %d\n", reg_string[reg], data_in);
            }
            
        }
    }
}