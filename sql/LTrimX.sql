SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		  Jim Richards
-- Create date: 5/1/2020
-- Description:	Remove leading white space, tabs, carriage returns, line feeds.
-- https://blog.sqlauthority.com/2008/10/10/sql-server-2008-enhenced-trim-function-remove-trailing-spaces-leading-spaces-white-space-tabs-carriage-returns-line-feeds/
-- =============================================
CREATE OR ALTER   FUNCTION [dbo].[LTrimX]
(
  @character_expression nvarchar(4000)
)
RETURNS nvarchar(4000)
AS
BEGIN
  DECLARE @trimchars VARCHAR(10)
  SET @trimchars = CHAR(9)+CHAR(10)+CHAR(13)+CHAR(32)

  IF @character_expression LIKE '[' + @trimchars + ']%' 
    SET @character_expression = SUBSTRING(@character_expression, PATINDEX('%[^' + @trimchars + ']%', @character_expression), 4000)
  RETURN @character_expression
END
GO