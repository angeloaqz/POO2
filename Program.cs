
using System;
using NLog;

class Program
{
    private static readonly Logger logger =
        LogManager.GetCurrentClassLogger();

    static void Main()
    {
        logger.Info("Inicio do programa");

        try
        {
            Console.WriteLine("EXERCICIO 3 - Conversao");

            string texto = "abc";

            try
            {
                int numero = int.Parse(texto);
                logger.Info("Conversao realizada: " + numero);
            }
            catch (Exception ex)
            {
                logger.Error(ex, "Erro ao converter texto para inteiro");
            }
            Console.WriteLine("\nEXERCICIO 4 - Conta");

            Conta conta1 = new Conta(100);

            try
            {
                logger.Info("Tentando sacar 200 reais");
                conta1.Sacar(200);

                logger.Info("Saque realizado com sucesso");
            }
            catch (Exception ex)
            {
                logger.Error(ex, "Erro ao realizar saque");
            }
            Console.WriteLine("\nEXERCICIO 5 - Niveis de log");

            logger.Info("Operacao normal realizada");

            logger.Warn("Tentativa de operacao com valor invalido");

            try
            {
                throw new Exception("Exemplo de excecao");
            }
            catch (Exception ex)
            {
                logger.Error(ex, "Uma excecao aconteceu");
            }
            Console.WriteLine("\nEXERCICIO 6 - Operacoes bancarias");

            Conta conta2 = new Conta(500);
            Conta conta3 = new Conta(300);

            try
            {
                logger.Info("Inicio do deposito de 100 reais");

                conta2.Depositar(100);

                logger.Info("Deposito realizado com sucesso");
            }
            catch (Exception ex)
            {
                logger.Error(ex, "Erro ao realizar deposito");
            }

            try
            {
                logger.Info("Inicio do saque de 50 reais");

                conta2.Sacar(50);

                logger.Info("Saque realizado com sucesso");
            }
            catch (Exception ex)
            {
                logger.Error(ex, "Erro ao realizar saque");
            }
            try
            {
                decimal valor = 100;

                logger.Info("Inicio da transferencia de " + valor);

                conta2.Sacar(valor);
                conta3.Depositar(valor);

                logger.Info("Transferencia realizada com sucesso");
            }
            catch (Exception ex)
            {
                logger.Error(ex, "Erro ao realizar transferencia");
            }

            Console.WriteLine("\nSaldo conta 2: " + conta2.Saldo);
            Console.WriteLine("Saldo conta 3: " + conta3.Saldo);

            try
            {
                conta2.Depositar(-10);
            }
            catch (ArgumentException ex)
            {
                logger.Warn(ex, "Tentativa de deposito com valor invalido");
            }
        }
        finally
        {
            logger.Info("Fim do programa");

            LogManager.Shutdown();
        }
    }
}

class Conta
{
    public decimal Saldo { get; private set; }

    public Conta(decimal saldo)
    {
        Saldo = saldo;
    }

    public void Depositar(decimal valor)
    {
        if (valor <= 0)
        {
            throw new ArgumentException("Valor de deposito invalido");
        }

        Saldo += valor;
    }

    public void Sacar(decimal valor)
    {
        if (valor <= 0)
        {
            throw new ArgumentException("Valor de saque invalido");
        }

        if (Saldo < valor)
        {
            throw new InvalidOperationException("Saldo insuficiente");
        }

        Saldo -= valor;
    }
}
