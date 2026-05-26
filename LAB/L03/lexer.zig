const std = @import("std");

pub const Token = union(enum) {
    numero: f64,
    invalido: void,
};

// Tabela de transições do DFA para reconhecimento de números de ponto flutuante
// =============================================================================================
// ESTADO ATUAL | Dígito [0-9] | Ponto (.) | Expoente [eE] | Sinal [+-] | Sufixo [fFlL] | Outros
// =============================================================================================
// S0 (Início)  | S1           | S3        | Erro          | Erro       | Erro          | Erro
// S1           | S1           | S2        | S5            | Erro       | Erro          | Erro
// S2 (Ok)      | S4           | Erro      | S5            | Erro       | S8            | Erro
// S3           | S4           | Erro      | Erro          | Erro       | Erro          | Erro
// S4 (Ok)      | S4           | Erro      | S5            | Erro       | S8            | Erro
// S5           | S7           | Erro      | Erro          | S6         | Erro          | Erro
// S6           | S7           | Erro      | Erro          | Erro       | Erro          | Erro
// S7 (Ok)      | S7           | Erro      | Erro          | Erro       | S8            | Erro
// S8 (Ok)      | Erro         | Erro      | Erro          | Erro       | Erro          | Erro
// =============================================================================================

const Estado = enum {
    s0, // Inicial
    s1, // Dígitos antes do ponto
    s2, // Ponto após dígitos (ex: "12.")
    s3, // Ponto sem dígitos antes (ex: ".")
    s4, // Dígitos após o ponto (ex: "12.3")
    s5, // Leu o 'e' ou 'E' do expoente
    s6, // Leu o sinal do expoente '+' ou '-'
    s7, // Leu os dígitos do expoente
    s8, // Leu o sufixo (f, F, l, L)
    erro,
};

fn reconhecer_numero(entrada: []const u8) Token {
    // Se a string for vazia falha.
    if (entrada.len == 0) return Token{ .invalido = {} };

    var estado_atual = Estado.s0;

    for (entrada) |caractere| {
        estado_atual = match_estado(estado_atual, caractere);

        // se dar erro em qualquer ponto para a leitura
        if (estado_atual == Estado.erro) {
            break;
        }
    }

    // Verifica se terminamos em um estado de aceitação (S2, S4, S7 ou S8)
    const valido = switch (estado_atual) {
        .s2, .s4, .s7, .s8 => true,
        else => false,
    };

    if (valido) {
        // Se a string terminou com  'f' ou 'L' remove o sufixo para que a conversão funcione corretamente.
        const slice_para_parse = if (estado_atual == .s8) entrada[0 .. entrada.len - 1] else entrada;

        // Converte a string validada para o tipo f64 do Zig
        const valor = std.fmt.parseFloat(f64, slice_para_parse) catch return Token{ .invalido = {} };
        return Token{ .numero = valor };
    }

    return Token{ .invalido = {} };
}

// Transições da nossa tabela DFA
fn match_estado(atual: Estado, c: u8) Estado {
    return switch (atual) {
        .s0 => switch (c) {
            '0'...'9' => .s1,
            '.' => .s3,
            else => .erro,
        },
        .s1 => switch (c) {
            '0'...'9' => .s1,
            '.' => .s2,
            'e', 'E' => .s5,
            else => .erro,
        },
        .s2 => switch (c) {
            '0'...'9' => .s4,
            'e', 'E' => .s5,
            'f', 'F', 'l', 'L' => .s8,
            else => .erro,
        },
        .s3 => switch (c) {
            '0'...'9' => .s4,
            else => .erro,
        },
        .s4 => switch (c) {
            '0'...'9' => .s4,
            'e', 'E' => .s5,
            'f', 'F', 'l', 'L' => .s8,
            else => .erro,
        },
        .s5 => switch (c) {
            '0'...'9' => .s7,
            '+', '-' => .s6,
            else => .erro,
        },
        .s6 => switch (c) {
            '0'...'9' => .s7,
            else => .erro,
        },
        .s7 => switch (c) {
            '0'...'9' => .s7,
            'f', 'F', 'l', 'L' => .s8,
            else => .erro,
        },
        .s8 => .erro,
        .erro => .erro,
    };
}

test "Teste reconhecimento de numero simples" {
    const entrada = "123.45";
    const esperado = Token{ .numero = 123.45 };
    const obtido = reconhecer_numero(entrada);
    try std.testing.expectEqual(esperado, obtido);
}

test "Teste ponto flutuante com expoente" {
    const entrada = "1.2e2";
    const esperado = Token{ .numero = 120.0 };
    const obtido = reconhecer_numero(entrada);
    try std.testing.expectEqual(esperado, obtido);
}

test "Teste ponto flutuante com expoente -" {
    const entrada = "1.2e-2";
    const esperado = Token{ .numero = 0.012 };
    const obtido = reconhecer_numero(entrada);
    try std.testing.expectEqual(esperado, obtido);
}

test "Teste ponto flutuante com expoente +" {
    const entrada = "1.2e+2";
    const esperado = Token{ .numero = 120.0 };
    const obtido = reconhecer_numero(entrada);
    try std.testing.expectEqual(esperado, obtido);
}

test "Teste inteiro ponto" {
    const entrada = "120.";
    const esperado = Token{ .numero = 120.0 };
    const obtido = reconhecer_numero(entrada);
    try std.testing.expectEqual(esperado, obtido);
}

test "Teste com ponto omitindo o zero inicial" {
    const entrada = ".5";
    const esperado = Token{ .numero = 0.5 };
    const obtido = reconhecer_numero(entrada);
    try std.testing.expectEqual(esperado, obtido);
}

test "Teste entrada float com sufixo 'f'" {
    const entrada = "12.5f";
    const esperado = Token{ .numero = 12.5 };
    const obtido = reconhecer_numero(entrada);
    try std.testing.expectEqual(esperado, obtido);
}

test "Teste entrada float com sufixo 'F'" {
    const entrada = "12.5F";
    const esperado = Token{ .numero = 12.5 };
    const obtido = reconhecer_numero(entrada);
    try std.testing.expectEqual(esperado, obtido);
}

test "Teste entrada long double com sufixo 'L' " {
    const entrada = "12.3L";
    const esperado = Token{ .numero = 12.3 };
    const obtido = reconhecer_numero(entrada);
    try std.testing.expectEqual(esperado, obtido);
}

test "Teste entrada long double com sufixo 'l' " {
    const entrada = "12.3l";
    const esperado = Token{ .numero = 12.3 };
    const obtido = reconhecer_numero(entrada);
    try std.testing.expectEqual(esperado, obtido);
}

test "Teste entrada inválida" {
    const entrada = "12.3.4";
    const esperado = Token{ .invalido = {} };
    const obtido = reconhecer_numero(entrada);
    try std.testing.expectEqual(esperado, obtido);
}

test "Teste entrada inválida letra" {
    const entrada = "12.3H";
    const esperado = Token{ .invalido = {} };
    const obtido = reconhecer_numero(entrada);
    try std.testing.expectEqual(esperado, obtido);
}

