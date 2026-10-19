package com.persistenciademo.demo;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import com.persistenciademo.demo.DTO.AuthRequest;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    @Autowired
    private JwtUtil jwtUtil;

    @PostMapping("/login")
    public String login(@RequestBody AuthRequest json_) {
        // Aquí validarías contra tu base de datos si el usuario existe.
        // Se debe retornar antes si existe o no el usuario.........
        // Como es un ejemplo básico, generamos el token directamente con el nombre enviado:
        return jwtUtil.generateToken(json_.getUsername());
    }
}