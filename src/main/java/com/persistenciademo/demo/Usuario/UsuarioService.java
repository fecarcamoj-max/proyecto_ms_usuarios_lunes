package com.persistenciademo.demo.Usuario;

import java.util.List;
import java.util.Optional;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestAttribute;

@Service 
public class UsuarioService {

    @Autowired 
    private UsuarioRepository usuarioRepository;

    // Leer
    public List<Usuario> getTraerUsuarios(){
        return (List<Usuario>) usuarioRepository.findAll();
    } 

    // Guardar
    public Usuario saveUsuario(Usuario usuario){
        return usuarioRepository.save(usuario);
    }

    // Consultar por ID específico:
    public Optional<Usuario> getUsuario(Integer id){
        return usuarioRepository.findById(id);
    }

}
