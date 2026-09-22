using System;

public class UsuarioNaoAutenticadoException : Exception
{
    public UsuarioNaoAutenticadoException(string mensagem) : base(mensagem)
    {
    }
}

public class Sistema
{
    private bool autenticado = false;

    public void AcessarRecurso()
    {
        if (!autenticado)
        {
            throw new UsuarioNaoAutenticadoException(
                "Usuário não autenticado. Faça login para acessar o recurso."
            );
        }

        Console.WriteLine("Recurso acessado com sucesso!");
    }
}

class Program
{
    static void Main()
    {
        try
        {
            Sistema sistema = new Sistema();

            sistema.AcessarRecurso();
        }
        catch (UsuarioNaoAutenticadoException ex)
        {
            Console.WriteLine("Erro: " + ex.Message);
        }
    }
}
