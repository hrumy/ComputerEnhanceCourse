package main  

import "core:fmt"
import "core:os"

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
            // register/memory to/from register 
            case 0b10001000..<0b10001011 : {
                d := bool((first_byte & 2) >> 1);
                w := bool( first_byte & 1);
                
                mod :=  second_byte >> 6;
                reg := (second_byte << 2) >> 5;
                rm  :=  second_byte & 7;
                
                switch mod {
                    // register mode
                    case 0b0011 : {
                        if d {
                            dst_bits = reg;
                            src_bits = rm;
                        }
                        else {
                            src_bits = reg;
                            dst_bits = rm;
                        }
        
                        reg_string := w ? Register_W1 : Register_W0;
        
                        src := reg_string[src_bits];
                        dst := reg_string[dst_bits];
        
                        fmt.printf("mov %s, %s\n", dst, src); 
                    }
                }
            }
    
        }
    }
}