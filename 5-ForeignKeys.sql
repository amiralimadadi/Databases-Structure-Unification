--======================================= 5. Foreign Key =======================================
/* 
This file holds the query for copying the reference database foreign keys to the destination database
To execute this, you need to replace "{Base}" with your reference database name 
	and replace "{Destination}" with your destination database name
This query creates a table called "#TempBase" in tempdb, so you need access to do that.
The query contains different parts like "adding new FK" and "deleting current FK".
*/

--********** 5.1 Add FK
Begin /*AddFK*/
If Object_ID ('tempdb.dbo.#TempBase', 'U') Is Not Null Drop Table #TempBase;
If Object_ID ('tempdb.dbo.#TempDestination', 'U') Is Not Null Drop Table #TempDestination;
Select	obj.name AS FK_NAME,
		sch.name AS [schema_name],
		tab1.name AS [table],
		col1.name AS [column],
		tab2.name AS [referenced_table],
		col2.name AS [referenced_column]
Into	#TempBase
From	{Base}.sys.foreign_key_columns fkc Inner Join
		{Base}.sys.objects obj On	obj.object_id = fkc.constraint_object_id Inner Join
		{Base}.sys.tables tab1 On	tab1.object_id = fkc.parent_object_id Inner Join
		{Base}.sys.schemas sch On	tab1.schema_id = sch.schema_id Inner Join
		{Base}.sys.columns col1 On	col1.column_id = parent_column_id And
									col1.object_id = tab1.object_id Inner Join
		{Base}.sys.tables tab2 On	tab2.object_id = fkc.referenced_object_id Inner Join
		{Base}.sys.columns col2 On	col2.column_id = referenced_column_id And
									col2.object_id = tab2.object_id

Select	obj.name AS FK_NAME,
		sch.name AS [schema_name],
		tab1.name AS [table],
		col1.name AS [column],
		tab2.name AS [referenced_table],
		col2.name AS [referenced_column]
Into	#TempDestination
From	{Destination}.sys.foreign_key_columns fkc Inner Join
		{Destination}.sys.objects obj On	obj.object_id = fkc.constraint_object_id Inner Join
		{Destination}.sys.tables tab1 On	tab1.object_id = fkc.parent_object_id Inner Join
		{Destination}.sys.schemas sch On	tab1.schema_id = sch.schema_id Inner Join
		{Destination}.sys.columns col1 On	col1.column_id = parent_column_id And
									col1.object_id = tab1.object_id Inner Join
		{Destination}.sys.tables tab2 On	tab2.object_id = fkc.referenced_object_id Inner Join
		{Destination}.sys.columns col2 On col2.column_id = referenced_column_id And
									col2.object_id = tab2.object_id

Select	*
From	#TempBase
Where	FK_NAME Not In
		(Select Distinct FK_NAME From #TempDestination)

Declare @FknameAFK nvarchar(50)
Declare @TableNameAFK nvarchar(50)

Declare @rowAFK int
Set @rowAFK = 0

Declare Cursor_AddFK Cursor For
Select	Distinct FK_NAME,[table]
From	#TempBase
Where	FK_NAME Not In
			(Select FK_NAME From #TempDestination)

Open		Cursor_AddFK
Fetch From	Cursor_AddFK
	Into	@FknameAFK,@TableNameAFK

While	@@Fetch_STATUS=0
	Begin
		Declare @AddFK NVARCHAR(MAX) = ''
		Select	@AddFK =
					'ALTER TABLE ' + @TableNameAFK+
					' ADD CONSTRAINT '+ @FknameAFK +' FOREIGN KEY ('+ c.[column]+
					') REFERENCES '+c.referenced_table+'('+c.referenced_column+')'
		From	#TempBase as c
		Where	c.[table] = @TableNameAFK And
				c.FK_NAME=@FknameAFK
		
		PRINT @AddFK
		--EXEC sys.sp_executesql @AddTable
		
		Fetch Next From	Cursor_AddFK
		Into @FknameAFK,@TableNameAFK
	END
Close		Cursor_AddFK
Deallocate	Cursor_AddFK
End /*AddFK*/

--********** 5.2 Delete FK
Begin /*DeleteFK*/
If Object_ID ('tempdb.dbo.#TempBase', 'U') Is Not Null Drop Table #TempBase;
If Object_ID ('tempdb.dbo.#TempDestination', 'U') Is Not Null Drop Table #TempDestination;

Select	obj.name AS FK_NAME,
		sch.name AS [schema_name],
		tab1.name AS [table],
		col1.name AS [column],
		tab2.name AS [referenced_table],
		col2.name AS [referenced_column]
Into	#TempBase
From	{Base}.sys.foreign_key_columns fkc Inner Join
		{Base}.sys.objects obj On	obj.object_id = fkc.constraint_object_id Inner Join
		{Base}.sys.tables tab1 On	tab1.object_id = fkc.parent_object_id Inner Join
		{Base}.sys.schemas sch On	tab1.schema_id = sch.schema_id Inner Join
		{Base}.sys.columns col1 On	col1.column_id = parent_column_id And
									col1.object_id = tab1.object_id Inner Join
		{Base}.sys.tables tab2 On	tab2.object_id = fkc.referenced_object_id Inner Join
		{Base}.sys.columns col2 On	col2.column_id = referenced_column_id And
									col2.object_id = tab2.object_id
Select	obj.name AS FK_NAME,
		sch.name AS [schema_name],
		tab1.name AS [table],
		col1.name AS [column],
		tab2.name AS [referenced_table],
		col2.name AS [referenced_column]
Into	#TempDestination
From	{Destination}.sys.foreign_key_columns fkc Inner Join
		{Destination}.sys.objects obj On	obj.object_id = fkc.constraint_object_id Inner Join
		{Destination}.sys.tables tab1 On	tab1.object_id = fkc.parent_object_id Inner Join
		{Destination}.sys.schemas sch On	tab1.schema_id = sch.schema_id Inner Join
		{Destination}.sys.columns col1 On	col1.column_id = parent_column_id And
									col1.object_id = tab1.object_id Inner Join
		{Destination}.sys.tables tab2 On	tab2.object_id = fkc.referenced_object_id Inner Join
		{Destination}.sys.columns col2 On	col2.column_id = referenced_column_id And
									col2.object_id = tab2.object_id

Select	*
From	#TempDestination
Where	FK_NAME Not In
			(Select Distinct FK_NAME From #TempBase)

Declare @FknameDFK nvarchar(50)
Declare @TableNameDFK nvarchar(50)

Declare @rowDFK int
Set @rowDFK = 0
Declare Cursor_DeleteFK Cursor For
Select	Distinct FK_NAME,[table]
From	#TempDestination
Where	FK_NAME Not In
			(Select FK_NAME From #TempBase)

Open		Cursor_DeleteFK
Fetch From	Cursor_DeleteFK
	Into	@FknameDFK,@TableNameDFK

While	@@Fetch_STATUS=0
	Begin
		Declare @DeleteFK NVARCHAR(MAX) = ''
		Select	@DeleteFK =
				'ALTER TABLE ' + @TableNameDFK +
				' DROP CONSTRAINT '+ @FknameDFK 
		From	#TempDestination as c
		Where	c.[table] = @TableNameDFK And
				c.FK_NAME=@FknameDFK
		
		PRINT @DeleteFK
		--EXEC sys.sp_executesql @AddTable
		Fetch Next From	Cursor_DeleteFK
		Into @FknameDFK,@TableNameDFK
	End
Close		Cursor_DeleteFK
Deallocate	Cursor_DeleteFK

End /*DeleteFK*/