//
//  MapperIdentifier.swift
//  iES
//
//  Created by Никита Пивоваров on 14.07.2024.
//

import Foundation

enum MapperIdentifier: UInt8 {
    case NROM = 0,
         MMC1 = 1,
         UxROM = 2,
         CNROM = 3,
         MMC3 = 4,
         MMC5 = 5,
         FFE_F4XXX = 6,
         AxROM = 7,
         _008 = 8,
         MMC2 = 9,
         MMC4 = 10,
         ColorDreams = 11,
         _012 = 12,
         CPROM = 13,
         _014 = 14,
         CF16_100in1 = 15,
         BandaiEPROM = 16,
         _017 = 17,
         JalecoSS8806 = 18,
         Namco163 = 19,
         _020 = 20,
         VRC4a_VRC4c = 21,
         VRC2a = 22,
         VRC2b_VRC4e_VRC4f = 23,
         VRC6a = 24,
         VRC2c_VRC4b_VRC4d = 25,
         VRC6b = 26,
         _027 = 27,
         Action_53 = 28,
         _029 = 29,
         UNRO_512 = 30,
         _031 = 31,
         Irem_G101 = 32,
         TC0190_TC0350 = 33,
         BNRO_NINA001 = 34,
         _035 = 35,
         TXC_01_22000_400 = 36,
         _037 = 37,
         UNL_PCI556 = 38,
         _039 = 39,
         NTDEC_2722 = 40,
         _041 = 41,
         _042 = 42,
         _043 = 43,
         _044 = 44,
         _045 = 45,
         _046 = 46,
         _047 = 47,
         _048 = 48,
         _049 = 49,
         _050 = 50,
         _051 = 51,
         _052 = 52,
         _053 = 53,
         _054 = 54,
         _055 = 55,
         _056 = 56,
         _057 = 57,
         _058 = 58,
         _059 = 59,
         _060 = 60,
         _061 = 61,
         _062 = 62,
         _063 = 63,
         RAMBO1 = 64,
         Irem_H3001 = 65,
         GxROM = 66,
         _067 = 67,
         Sunsoft_4 = 68,
         Sunsoft_5 = 69,
         _070 = 70,
         Camerica = 71,
         _072 = 72,
         VRC3 = 73,
         WaixingMMC3Clone = 74,
         VRC1 = 75,
         Namco109 = 76,
         _077 = 77,
         _078 = 78,
         NINA_03_06 = 79,
         _080 = 80,
         _081 = 81,
         Taito_X117 = 82,
         _083 = 83,
         _084 = 84,
         VRC7 = 85,
         JALECO_JF13 = 86,
         _087 = 87,
         Namco_118 = 88,
         _089 = 89,
         _090 = 90,
         _091 = 91,
         _092 = 92,
         _093 = 93,
         _094 = 94,
         Namco_1xx = 95,
         _096 = 96,
         Ire_74161_32 = 97,
         _098 = 98,
         _099 = 99,
         _100 = 100,
         _101 = 101,
         _102 = 102,
         _103 = 103,
         _104 = 104,
         NES_EVENT = 105,
         _106 = 106,
         _107 = 107,
         _108 = 108,
         _109 = 109,
         _110 = 110,
         _111 = 111,
         _112 = 112,
         _113 = 113,
         _114 = 114,
         _115 = 115,
         _116 = 116,
         _117 = 117,
         TxSROM = 118,
         TQROM = 119,
         _120 = 120,
         _121 = 121,
         _122 = 122,
         _123 = 123,
         _124 = 124,
         _125 = 125,
         _126 = 126,
         _127 = 127,
         _128 = 128,
         _129 = 129,
         _130 = 130,
         _131 = 131,
         _132 = 132,
         _133 = 133,
         _134 = 134,
         _135 = 135,
         _136 = 136,
         _137 = 137,
         _138 = 138,
         _139 = 139,
         _140 = 140,
         _141 = 141,
         _142 = 142,
         _143 = 143,
         _144 = 144,
         _145 = 145,
         _146 = 146,
         _147 = 147,
         _148 = 148,
         _149 = 149,
         _150 = 150,
         _151 = 151,
         _152 = 152,
         _153 = 153,
         _154 = 154,
         _155 = 155,
         _156 = 156,
         _157 = 157,
         _158 = 158,
         _159 = 159,
         _160 = 160,
         _161 = 161,
         _162 = 162,
         _163 = 163,
         _164 = 164,
         _165 = 165,
         SUBOR1 = 166,
         SUBOR2 = 167,
         _168 = 168,
         _169 = 169,
         _170 = 170,
         _171 = 171,
         _172 = 172,
         _173 = 173,
         _174 = 174,
         _175 = 175,
         _176 = 176,
         _177 = 177,
         _178 = 178,
         _179 = 179,
         _180 = 180,
         _181 = 181,
         _182 = 182,
         _183 = 183,
         _184 = 184,
         _185 = 185,
         _186 = 186,
         _187 = 187,
         _188 = 188,
         _189 = 189,
         _190 = 190,
         _191 = 191,
         _192 = 192,
         _193 = 193,
         _194 = 194,
         _195 = 195,
         _196 = 196,
         _197 = 197,
         _198 = 198,
         _199 = 199,
         _200 = 200,
         _201 = 201,
         _202 = 202,
         _203 = 203,
         _204 = 204,
         _205 = 205,
         Namcot118_TengenMimic1 = 206,
         _207 = 207,
         _208 = 208,
         _209 = 209,
         _210 = 210,
         _211 = 211,
         _212 = 212,
         _213 = 213,
         _214 = 214,
         _215 = 215,
         _216 = 216,
         _217 = 217,
         _218 = 218,
         _219 = 219,
         _220 = 220,
         _221 = 221,
         _222 = 222,
         _223 = 223,
         _224 = 224,
         _225 = 225,
         _226 = 226,
         _227 = 227,
         Action52 = 228,
         _229 = 229,
         _230 = 230,
         _231 = 231,
         CamericaQuattro = 232,
         _233 = 233,
         _234 = 234,
         _235 = 235,
         _236 = 236,
         _237 = 237,
         _238 = 238,
         _239 = 239,
         _240 = 240,
         _241 = 241,
         _242 = 242,
         _243 = 243,
         _244 = 244,
         _245 = 245,
         _246 = 246,
         _247 = 247,
         _248 = 248,
         _249 = 249,
         _250 = 250,
         _251 = 251,
         _252 = 252,
         _253 = 253,
         _254 = 254,
         _255 = 255
    
    var isSupported: Bool {
        switch self {
        case .NROM,
                .UxROM,
                .MMC1,
                .CNROM,
                .MMC3,
                .AxROM,
                .MMC2,
                .MMC4,
                .ColorDreams,
                .GxROM,
                .Namcot118_TengenMimic1,
                .MMC5,
                .VRC2b_VRC4e_VRC4f,
                .VRC2c_VRC4b_VRC4d,
                .VRC7,
                .NTDEC_2722,
                ._078,
                ._087,
                .TxSROM,
                .TQROM,
                .CamericaQuattro:
            return true
        default:
            return false
        }
    }
    
    var hasExpansionAudio: Bool {
        switch self {
        case .Namco163, .VRC6a, .VRC6b, .VRC7, .MMC5:
            return true
        default:
            return false
        }
    }
}
