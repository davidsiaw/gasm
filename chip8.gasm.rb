asm do
  instructions do
    op "nop", "1000 0000 0000 0000"

    # Generate matchers for hex values for register
    def vp(pattern, bits)
      if pattern.include?('V<x>')
        hex_letters = %w[a b c d e f A B C D E F]
        hex_letters.each do |register_x|
            pattern_a = pattern.gsub('V<x>', "V#{register_x}")
            bits_a = bits.gsub('xxxx', "#{register_x.to_i(16).to_s(2)}")

            if pattern_a.include?('V<y>')
                hex_letters.each do |register_y|
                    pattern_b = pattern_a.gsub('V<y>', "V#{register_y}")
                    bits_b = bits_a.gsub('yyyy', "#{register_y.to_i(16).to_s(2)}")
                    op pattern_b, bits_b 
                end
            end
            op pattern_a, bits_a
        end
      end

      op pattern, bits
    end

    vp "ld V<x>, [I]"        , "1111 xxxx 0110 0101" # LD Vx, [I]
    vp "ld [I], V<x>"        , "1111 xxxx 0101 0101" # LD [I], Vx
    vp "ld B, V<x>"          , "1111 xxxx 0011 0011" # LD B, Vx
    vp "ld F, V<x>"          , "1111 xxxx 0010 1001" # LD F, Vx
    vp "add I, V<x>"         , "1111 xxxx 0001 1110" # ADD I, Vx
    vp "ld ST, V<x>"         , "1111 xxxx 0001 1000" # LD ST, Vx
    vp "ld DT, V<x>"         , "1111 xxxx 0001 0101" # LD DT, Vx
    vp "ld V<x>, K"          , "1111 xxxx 0000 1010" # LD Vx, K
    vp "ld V<x>, DT"         , "1111 xxxx 0000 0111" # LD Vx, DT
    
    vp "sknp V<x>"           , "1110 xxxx 1010 0001" # SKNP Vx
    vp "skp V<x>"            , "1110 xxxx 1001 1110" # SKP Vx
    vp "drw V<x>, V<y>, <n>" , "1101 xxxx yyyy nnnn" # DRW Vx, Vy, n
    vp "rnd V<x>, <k>"       , "1100 xxxx kkkk kkkk" # RND Vx, k; rnd Vx & k
    vp "jp V0, <n>"          , "1011 nnnn nnnn nnnn" # JP V0, n; jump n + V0
    vp "ld I, <n>"           , "1010 nnnn nnnn nnnn" # LD I, n
    vp "sne V<x>, V<y>"      , "1001 xxxx yyyy 0000" # SNE Vx, Vy

    vp "shl V<x>"            , "1000 xxxx yyyy 1110" # SHL Vx
    vp "subn V<x>, V<y>"     , "1000 xxxx yyyy 0111" # SUBN Vx, Vy
    vp "shr V<x>"            , "1000 xxxx yyyy 0110" # SHR Vx
    vp "sub V<x>, V<y>"      , "1000 xxxx yyyy 0101" # SUB Vx, Vy
    vp "add V<x>, V<y>"      , "1000 xxxx yyyy 0100" # ADD Vx, Vy
    vp "xor V<x>, V<y>"      , "1000 xxxx yyyy 0011" # XOR Vx, Vy
    vp "and V<x>, V<y>"      , "1000 xxxx yyyy 0010" # AND Vx, Vy
    vp "or V<x>, V<y>"       , "1000 xxxx yyyy 0001" # OR Vx, Vy
    vp "ld V<x>, V<y>"       , "1000 xxxx yyyy 0000" # LD Vx, Vy

    vp "add V<x>, <k>"       , "0111 xxxx kkkk kkkk" # ADD Vx, k
    vp "ld V<x>, <k>"        , "0110 xxxx kkkk kkkk" # LD Vx, k
    vp "se V<x>, V<y>"       , "0101 xxxx yyyy 0000" # SE Vx, Vy
    vp "sne V<x>, <k>"       , "0100 xxxx kkkk kkkk" # SNE Vx, k
    vp "se V<x>, <k>"        , "0011 xxxx kkkk kkkk" # SE Vx, k
    vp "call <n>"            , "0010 nnnn nnnn nnnn"
    vp "jp <n>"              , "0001 nnnn nnnn nnnn"
    vp "ret"                 , "0000 0000 1110 1110"
    vp "cls"                 , "0000 0000 1110 0000"
  end
end
