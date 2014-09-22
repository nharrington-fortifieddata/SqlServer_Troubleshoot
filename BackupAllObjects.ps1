#PLEASE PUT THE DRIVE NAME YOU WANT TO WRITE TO BELOW EXAMPLE "C:"
$rootDrive = "H:"

#the full path of the file that you want to script the stored procs to
$strDate = (get-Date).tostring("yyyyMMddHHssmm")

[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | out-null

$MyScripter=new-object ("Microsoft.SqlServer.Management.Smo.Scripter")
$srv=New-Object "Microsoft.SqlServer.Management.Smo.Server" "localhost"
foreach($sqlDatabase in $srv.databases)
{
	$procs = $sqlDatabase.StoredProcedures
	$views = $sqlDatabase.views
	$tables = $sqlDatabase.tables
	$udfs = $sqlDatabase.UserDefinedFunctions
	$sqlDatabaseName = $sqlDatabase.name
	$MyScripter.Server=$srv
	
	
	"************* $sqlDatabaseName"
	
	
	
	

		
	#STORED PROCEDURES
	if($procs -ne $null)
	{
		foreach ($proc in $procs)
		{
			#Assuming that all non-system stored procs have proper naming convention and don't use prefixes like "sp_"
			if ( $proc.Name.IndexOf("sp_") -eq -1 -and $proc.Name.IndexOf("xp_") -eq -1  -and $proc.Name.IndexOf("dt_") -eq -1)
			{
				
				$fileName = $proc.name
				"Scripting SP $fileName"
				$scriptfile = "$rootDrive\DatabaseScripts\$sqlDatabaseName\$strDate\StoredProcedures\$filename.sql"
				New-Item $rootDrive\DatabaseScripts -type directory -force | out-null
				New-Item $rootDrive\DatabaseScripts\$sqlDatabaseName -type directory -force | out-null
				New-Item $rootDrive\DatabaseScripts\$sqlDatabaseName\$strDate -type directory -force | out-null
				New-Item $rootDrive\DatabaseScripts\$sqlDatabaseName\$strDate\StoredProcedures -type directory -force | out-null
				$MyScripter.Options.FileName = $scriptfile
				#AppendTofile has to be 'true' in order that all the procs' scripts will be appended at the end
				$MyScripter.Options.AppendToFile = "true"
				$MyScripter.Script($proc)|out-null
			}
		} 
	}
	
	#VIEWS
	if($views -ne $null)
	{
		foreach ($view in $views)
		{
			#Only script views that are properly named
			if ( $view.Name.IndexOf("View") -eq 0)
			{

				
				$fileName = $view.name
				"Scripting View $fileName"
				$scriptfile = "$rootDrive\DatabaseScripts\$sqlDatabaseName\$strDate\Views\$fileName.sql"
				New-Item $rootDrive\DatabaseScripts -type directory -force | out-null
				New-Item $rootDrive\DatabaseScripts\$sqlDatabaseName -type directory -force | out-null
				New-Item $rootDrive\DatabaseScripts\$sqlDatabaseName\$strDate -type directory -force | out-null
				New-Item $rootDrive\DatabaseScripts\$sqlDatabaseName\$strDate\Views -type directory -force | out-null
				$MyScripter.Options.FileName = $scriptfile
				#AppendTofile has to be 'true' in order that all the procs' scripts will be appended at the end
				$MyScripter.Options.AppendToFile = "true"
				$MyScripter.Script($view)|out-null
			}
		} 
	}
	
	
		#TABLES
	if($tables -ne $null)
	{
						
				$scriptfile = "$rootDrive\DatabaseScripts\$sqlDatabaseName\$strDate\AllTables.sql"
				New-Item $rootDrive\DatabaseScripts -type directory -force | out-null
				New-Item $rootDrive\DatabaseScripts\$sqlDatabaseName -type directory -force | out-null
				New-Item $rootDrive\DatabaseScripts\$sqlDatabaseName\$strDate -type directory -force | out-null
				$MyScripter.Options.FileName = $scriptfile
				#AppendTofile has to be 'true' in order that all the procs' scripts will be appended at the end
				"Scripting out creation script for all tables in $sqlDatabasename"
				$MyScripter.Options.AppendToFile = "true"
				$MyScripter.Script($tables)|out-null
		foreach ($table in $tables)
		{			
				$tableName = $table.name
				#TRIGGERS
				if($table.triggers -ne $null)
				{
					foreach ($trigger in $table.triggers)
					{
						
						$fileName = $trigger.name
						"Scripting trigger $fileName"
						$scriptfile = "$rootDrive\DatabaseScripts\$sqlDatabaseName\$strDate\Triggers\$fileName.sql"
						New-Item $rootDrive\DatabaseScripts -type directory -force | out-null
						New-Item $rootDrive\DatabaseScripts\$sqlDatabaseName -type directory -force | out-null
						New-Item $rootDrive\DatabaseScripts\$sqlDatabaseName\$strDate -type directory -force | out-null
						New-Item $rootDrive\DatabaseScripts\$sqlDatabaseName\$strDate\Triggers -type directory -force | out-null
						$MyScripter.Options.FileName = $scriptfile
						#AppendTofile has to be 'true' in order that all the procs' scripts will be appended at the end
						$MyScripter.Options.AppendToFile = "true"
						$MyScripter.Script($trigger)|out-null
					}
				}
				
				
				
		} 
	}
	
	#USER DEFINED FUNCTIONS
	if($udfs -ne $null)
	{
		foreach ($udf in $udfs)
		{
			if ( $udf.Name.IndexOf("dm_") -eq -1 -and $udf.Name.IndexOf("fn_") -eq -1)
				{
					$fileName = $udf.name
					"Scripting UDF $fileName"
					$scriptfile = "$rootDrive\DatabaseScripts\$sqlDatabaseName\$strDate\UDFs\$fileName.sql"
					New-Item $rootDrive\DatabaseScripts -type directory -force | out-null
					New-Item $rootDrive\DatabaseScripts\$sqlDatabaseName -type directory -force | out-null
					New-Item $rootDrive\DatabaseScripts\$sqlDatabaseName\$strDate -type directory -force | out-null
					New-Item $rootDrive\DatabaseScripts\$sqlDatabaseName\$strDate\UDFs -type directory -force | out-null
					$MyScripter.Options.FileName = $scriptfile
					#AppendTofile has to be 'true' in order that all the procs' scripts will be appended at the end
					$MyScripter.Options.AppendToFile = "true"
					$MyScripter.Script($udf)|out-null
				}
		}
	} 





} 