using System;

public class DivisaoPorZeroException : Exception
{
    public DivisaoPorZeroException(string mensagem) : base(mensagem)
    {
    }
}

class Program
{
    public static double Dividir(double numero1, double numero2)
    {
        if (numero2 == 0)
        {
            throw new DivisaoPorZeroException(
                "Não é possível dividir por zero."
            );
        }

        return numero1 / numero2;
    }

    static void Main()
    {
        try
        {
            double resultado = Dividir(10, 0);

            Console.WriteLine("Resultado: " + resultado);
        }
        catch (DivisaoPorZeroException ex)
        {
            Console.WriteLine("Erro: " + ex.Message);
        }
    }
}