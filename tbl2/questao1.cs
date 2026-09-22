using System;

public class IdadeInvalidaException : Exception
{
    public IdadeInvalidaException(string mensagem) : base(mensagem)
    {
    }
}

public class Pessoa
{
    public string Nome { get; set; }
    public int Idade { get; set; }

    public Pessoa(string nome, int idade)
    {
        if (idade < 0 || idade > 120)
        {
            throw new IdadeInvalidaException(
                "A idade deve estar entre 0 e 120 anos."
            );
        }

        Nome = nome;
        Idade = idade;
    }
}

class Program
{
    static void Main()
    {
        try
        {
            Console.Write("Digite o nome da pessoa: ");
            string nome = Console.ReadLine();

            Console.Write("Digite a idade da pessoa: ");
            int idade = int.Parse(Console.ReadLine());

            Pessoa pessoa = new Pessoa(nome, idade);

            Console.WriteLine("Pessoa cadastrada com sucesso!");
        }
        catch (IdadeInvalidaException ex)
        {
            Console.WriteLine("ERRO: " + ex.Message);
        }
    }
}
