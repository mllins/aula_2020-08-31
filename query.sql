CREATE DATABASE aula_2020_08_31
GO
USE aula_2020_08_31

-- Exercício 01

CREATE TABLE pessoa (
cpf				CHAR(14),
nome			VARCHAR(100),
endereco		VARCHAR(120),
numero			INT,
cep				CHAR(9))


CREATE PROCEDURE sp_testacpf (@cpf CHAR(14), @resp INT OUTPUT)
AS
	DECLARE @charat			CHAR(1),
			@posicao		INT,
			@multiplicador	INT,
			@valoranterior	INT,
			@valor			INT,
			@iguais			INT,
			@erros			INT,
			@digito1		INT,
			@digito2		INT,
			@msgerro		VARCHAR(MAX)

	-- Inicialização das ariáveis

	SET @posicao = 1
	SET @valor = -1
	SET @valoranterior = -1
	SET @erros = 0
	SET @digito1 = 0
	SET @digito2 = 0
	SET @multiplicador = 10
	SET @resp = 0

	-- Testa se o CPF tem tamanho compatível com a quantidade de caracteres necessárias
	IF(LEN(@cpf)=14)
	BEGIN
		WHILE (@posicao<=12)
		BEGIN
			-- Atualiza o valor anterior, se necessário (a partir da segunda posição)
			IF(@posicao>1)
			BEGIN
				SET @valoranterior = @valor
			END

			-- Obtém o caractere na posicao indicada
			SET @charat = SUBSTRING(@cpf,@posicao,1)

			-- Testa se a posicao é ponto ou traço (Múltiplos de 4 devem ser)
			IF(@posicao%4>0)
			BEGIN

				-- Testa se é um número
				IF(@charat >= '0' AND @charat <='9')
				BEGIN

					-- Converte o número para inteiro
					SET @valor = CAST(@charat AS INT)

					-- Caso o valor obtido é igual ao anterior, atualiza o contador de iguais ou o zera, em caso contrário
					IF(@valor = @valoranterior)
					BEGIN
						SET @iguais = @iguais + 1
					END
					ELSE
					BEGIN
						SET @iguais = 0
					END

					-- Utiliza o valor obtido para para o cálculo das somas verificadoras
					SET @digito1 = @digito1 + @valor*@multiplicador
					SET @digito2 = @digito2 + @valor*(@multiplicador+1)
	--				PRINT CAST(@posicao AS CHAR(5)) + ' | ' + CAST(@valor AS CHAR(5)) + ' | ' + 
	--				CAST(@multiplicador AS CHAR(5)) + ' | ' + CAST(@digito1 AS CHAR(5)) + ' | ' +  
	--				CAST((1+@multiplicador) AS CHAR(5)) + ' | ' + CAST(@digito2 AS CHAR(5))
					SET @multiplicador = @multiplicador - 1
				END
				ELSE
				BEGIN
					-- Não é número onde deveria ser. Aumenta o contador de erros
					SET @erros = @erros + 1
				END
			END
			ELSE
			BEGIN
				-- Testa se em posições não numéricas tem '.' ou '-' no lugar certo
				IF(@posicao<10 AND @charat<>'.' OR @posicao=10 AND @charat<>'-')
				BEGIN
					-- Atualiza o contador de erros
					SET @erros = @erros + 1
				END
			END
			SET @posicao = @posicao +1
		END

		-- Converte seus valores de verificação em dígitos verificadoers
		SET @digito1 = @digito1 % 11
		IF (@digito1 < 2)
		BEGIN
			SET @digito1 = 0
		END
		ELSE
		BEGIN
			SET @digito1 = 11 - @digito1
		END

		-- Acrescenta o primeiro dígito verificador no cálculo do segundo
		SET @digito2 = @digito2 + @digito1*2

		SET @digito2 = @digito2 % 11
		IF (@digito2 < 2)
		BEGIN
			SET @digito2 = 0
		END
		ELSE
		BEGIN
			SET @digito2 = 11 - @digito2
		END

		-- verifica se todos os dígitos são iguais
		IF(@iguais=9 AND @valor=@digito1 AND @valor=@digito2)
		BEGIN
			SET @erros = @erros+1
		END

		-- Obtém os dígitos de verificação do CPF
		SET @valor = CAST(SUBSTRING(@cpf,13,2) AS INT)

		-- Se não coincidem o calculado do obtido, atualiza o contador de erros
		SET @valoranterior =  @digito1*10+@digito2
		IF(@valor <> @digito1 * 10 + @digito2)
		BEGIN
			SET @erros = @erros + 1
		END
	END
	ELSE
	BEGIN
		-- CPF de tamanho incompatível
		SET @erros = @erros + 1
	END

	-- TESTA SE HOUVE ERROS NO CÁLCULO DE CPF
	IF (@erros=0)
	BEGIN
		SET @resp = 1
	END
	ELSE
	BEGIN
		SET @msgerro = 'CPF inválido.'
		IF(@valor>-1)
		BEGIN
			SET @msgerro = @msgerro + ' Esperado: ' + CAST(@valor AS VARCHAR(10)) + '. Obtido:' + CAST(@valoranterior AS VARCHAR(10))
		END
		SET @msgerro = @msgerro + ' Foram encontrados ' + CAST(@erros AS VARCHAR(10)) + ' erros.'
		RAISERROR(@msgerro, 16, 1)
	END

CREATE PROCEDURE sp_insere_pessoa(@cpf CHAR(14), 
			@nome VARCHAR(100),
			@endereco VARCHAR(120),
			@numero INT,
			@cep CHAR(9))
AS
	DECLARE @resp	INT,
			@valid	INT

	SET @valid = (SELECT COUNT(*) FROM pessoa WHERE cpf = @cpf)

	IF @valid = 1
	BEGIN
		RAISERROR('CPF já cadastrado', 16, 1)
	END
	ELSE
	BEGIN
		SET @valid = 0

		EXEC sp_testacpf @cpf, @resp OUTPUT

		IF LEN(@nome)>=5
		BEGIN
			SET @valid = @valid + 1
		END

		IF LEN(@endereco)>=5
		BEGIN
			SET @valid = @valid + 1
		END

		IF @numero>0
		BEGIN
			SET @valid = @valid + 1
		END

		IF LEN(@cep)=9
		BEGIN
			SET @valid = @valid + 1
		END
    
		IF @resp = 1 AND @valid = 4
		BEGIN
			INSERT INTO pessoa VALUES
			(@cpf, @nome, @endereco, @numero, @cep)
		END
		ELSE
		BEGIN
			RAISERROR('Há erro na entrada de dados.', 16, 1)
		END
	END

EXEC sp_insere_pessoa '222.333.666-38','Fulano de Tal','Rua Akido Lado', 64, '08025-999'

DECLARE @resp INT
EXEC sp_testacpf '222.333.666-38',@resp OUTPUT
PRINT @resp

-- Exercício 02

CREATE TABLE aluno (
codigo_aluno		INT IDENTITY,
nome				VARCHAR(100))

CREATE TABLE atividade (
codigo				INT,
descricao			VARCHAR(500),
imc					DECIMAL(5,2))

INSERT INTO atividade VALUES
(1,'Corrida + Step',18.5),
(2,'Biceps + Costas + Pernas',24.9),
(3,'Esteira + Biceps + Costas + Pernas',29.9),
(4,'Bicicleta + Biceps + Costas + Pernas',34.9),
(5,'Esteira + Bicicleta',39.9)

CREATE TABLE atividadesaluno (
codigo_aluno		INT,
altura				DECIMAL(4,2),
peso				DECIMAL(6,2),
imc					DECIMAL(5,2),
atividade			INT)

CREATE PROCEDURE sp_busca_atividade (@imc DECIMAL(5,2), @atividade INT OUTPUT)
AS
	PRINT 'Buscando atividade para IMC = ' + CAST(@imc AS VARCHAR(10)) + '...'
	IF(@imc>39.9)
	BEGIN
		SET @atividade = 5
	END
	ELSE
	BEGIN
		SET @atividade = (SELECT MIN(codigo) FROM atividade WHERE imc>=@imc)
	END

CREATE PROCEDURE sp_calculo_imc (@peso DECIMAL(6,2), 
				@altura		DECIMAL(4,2),
				@imc		DECIMAL(5,2) OUTPUT)
AS
	PRINT 'Calculando IMC para peso = ' + CAST(@peso AS VARCHAR(10)) + 
		' e altura = ' + CAST(@altura AS VARCHAR(10)) + '...'
	SET @imc = @peso / (@altura * @altura)

CREATE PROCEDURE sp_insere_aluno (@nome VARCHAR(100), 
				@peso	DECIMAL(6,2),
				@altura	DECIMAL(4,2))
AS
	DECLARE @imc		DECIMAL(5,2),
			@cont		INT,
			@codaluno	INT,
			@codativ	INT

	SET @cont = (SELECT COUNT(*) FROM aluno WHERE nome = @nome)
	IF(@cont = 0)
	BEGIN
		INSERT INTO aluno (nome) VALUES (@nome)
		SET @codaluno = (SELECT codigo_aluno FROM aluno WHERE nome = @nome)
		EXEC sp_calculo_imc @peso, @altura, @imc OUTPUT
		EXEC sp_busca_atividade @imc, @codativ OUTPUT
		INSERT INTO atividadesaluno (codigo_aluno, peso, altura, imc, atividade) VALUES
			(@codaluno, @peso, @altura, @imc, @codativ)
	END
	ELSE
	BEGIN
		PRINT 'Dados inconclusivos para inserir um aluno.'
	END

CREATE PROCEDURE sp_atualiza_dados (@codaluno INT, @peso DECIMAL(6,2),
				@altura	DECIMAL(4,2))
AS
	DECLARE @imc		DECIMAL(5,2),
			@cont		INT,
			@codativ	INT

	SET @cont = (SELECT COUNT(*) FROM atividadesaluno WHERE codigo_aluno = @codaluno)
	IF(@cont = 1)
	BEGIN
		EXEC sp_calculo_imc @peso, @altura, @imc OUTPUT
		EXEC sp_busca_atividade @imc, @codativ OUTPUT
		UPDATE atividadesaluno SET peso = @peso, altura = @altura,
				imc = @imc, atividade = @codativ
				WHERE codigo_aluno = @codaluno

	END
	ELSE
	BEGIN
		PRINT 'Dados inconclusíveis para alterar os dados de atividade.'
	END

CREATE PROCEDURE sp_processa_aluno (@nome VARCHAR(100), @codaluno INT,
		@peso	DECIMAL(6,2), @altura	DECIMAL(4,2))
AS
	PRINT 'Nome: '
	PRINT @nome
	PRINT 'Código: ' 
	PRINT @codaluno
	PRINT 'Peso:'
	PRINT @peso
	PRINT 'Altura:'
	PRINT @altura

	IF @codaluno IS NULL
	BEGIN
		PRINT 'Tentando inserir novo aluno...'
		IF @nome IS NOT NULL AND @peso IS NOT NULL AND @altura IS NOT NULL
		BEGIN
			EXEC sp_insere_aluno @nome, @peso, @altura
		END
		ELSE
		BEGIN
			PRINT @nome + ' - ' + CAST(@peso AS VARCHAR(6)) + ' - ' + CAST(@altura AS VARCHAR(5))
			RAISERROR('Faltam dados para acrescentar ao banco.', 16, 1)
		END
	END
	ELSE
	BEGIN
		PRINT 'Tentando atualizar dados existentes de aluno...'
		IF @peso IS NOT NULL AND @altura IS NOT NULL
		BEGIN
			EXEC sp_atualiza_dados @codaluno, @peso, @altura
		END
		ELSE
		BEGIN
			RAISERROR('Faltam dados para atualizar o banco.', 16, 1)
		END
	END

CREATE VIEW v_alunoatividade
AS
SELECT al.nome, aa.peso, aa.altura, aa.imc, at.descricao FROM aluno AS al
		INNER JOIN atividadesaluno AS aa ON al.codigo_aluno = aa.codigo_aluno 
		INNER JOIN atividade AS at ON aa.atividade = at.codigo


DROP PROCEDURE sp_processa_aluno
DROP PROCEDURE sp_atualiza_dados
DROP PROCEDURE sp_insere_aluno
DROP PROCEDURE sp_calculo_imc
DROP PROCEDURE sp_busca_atividade

DROP TABLE atividadesaluno
DROP TABLE atividade
DROP TABLE aluno

EXEC sp_processa_aluno 'Godofredo Galdêncio', NULL, 65.4, 1.70
EXEC sp_processa_aluno 'Menegerebe Costa Curta', NULL, 45, 1.55
EXEC sp_processa_aluno 'Menegerebe Costa Curta', 2, 48, 1.55
EXEC sp_processa_aluno 'Aristogildo Epitáfio', NULL, 100, 1.80
EXEC sp_processa_aluno 'Marietta Triceratops', NULL, 98.4, 1.68
EXEC sp_processa_aluno 'Jiu Zeppe Gari Balde', NULL, 85.4, 2.03
EXEC sp_processa_aluno 'Ana Nias Peque Naga Fanhoto', NULL, 62.4, 1.21
EXEC sp_processa_aluno NULL, 6, 58.4, 1.21

DECLARE @cod_atv INT
EXEC sp_busca_atividade 21,@cod_atv OUTPUT
PRINT @cod_atv


SELECT * FROM aluno
SELECT * FROM atividade
SELECT * FROM atividadesaluno
SELECT * FROM v_alunoatividade

SELECT v.*, a.imc FROM v_alunoatividade AS v
	INNER JOIN atividade AS a ON v.descricao = a.descricao
