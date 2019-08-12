
local settings = {};
settings.Query = {};
settings.Filename = {};

settings.Query[1]= GetSetting("Query1"):match("[^|]+");
settings.Filename[1] = GetSetting("Query1"):match("|.+"):gsub("|%s?", "");
if GetSetting("Query2"):find("%w") then
	settings.Query[2] = GetSetting("Query2"):match("[^|]+");
	settings.Filename[2] = GetSetting("Query2"):match("|.+"):gsub("|%s?", "");
end
if GetSetting("Query3"):find("%w") then
	settings.Query[3] = GetSetting("Query3"):match("[^|]+");
	settings.Filename[3] = GetSetting("Query3"):match("|.+"):gsub("|%s?", "");
end
settings.RunTimes = GetSetting("RunTimes");
settings.RunDays = GetSetting("Rundays"):lower();
settings.FilePath = GetSetting("FilePath") 
settings.Exclusions = GetSetting("Exclusions");

function Init()
	RegisterSystemEventHandler("SystemTimerElapsed", "RunISSReport");
end

function RunISSReport()
	
	local curTime = os.date("%H%M");
	local curDay = os.date("%A"):lower();

	if not (settings.RunTimes:find(curTime) and settings.RunDays:find(curDay)) then -- Only proceeds to run the rest when the day and time match the settings.
		return;
	end
	
	for ct = 1, #settings.Query do
	
		local query = settings.Query[ct];
		
		if settings.Exclusions:match("%w") then
			query = query .. " AND NVTGC NOT IN (" .. settings.Exclusions .. ")";
		end

		local report = "";
		
		local results = PullData(query);
		if not results then -- If no results, no need to generate a file.
			return;
		end
		
		for dt = 0, results.Columns.Count - 1 do -- Gets columns.
			report = report .. '"' .. results.Columns:get_Item(dt).ColumnName .. '"'.. ",";
		end

		report = report .. "\n";

		for dt = 0, results.Rows.Count - 1 do -- Gets rows.
			
			for et = 0, results.Columns.Count - 1 do
				report = report .. '"' .. tostring(results.Rows:get_Item(dt):get_Item(et)) .. '"' .. ",";
			end
		
			report = report .. "\n";
		end
		
		report = report:gsub(": %d+", "");
		
		LogDebug("CT IS: " .. ct);
		Debugger(settings.FilePath .. settings.Filename[ct]);
		
		local file = assert(io.open(settings.FilePath .. settings.Filename[ct] .. "_" .. os.date("%m-%d-%Y, %H.%M") .. ".csv", "w+"));
		if not file then
			file:close();
			return;
		end
		io.output(file);
		file:write(report);
		file:close();
	
	end
end

function PullData(query) -- Used for SQL queries that will return more than one result.
	local connection = CreateManagedDatabaseConnection();
	function PullData2()
		connection.QueryString = query;
		connection:Connect();
		local results = connection:Execute();
		connection:Disconnect();
		connection:Dispose();
		
		return results;
	end
	
	local success, results = pcall(PullData2, query);
	if not success then
		LogDebug("Problem with SQL query: " .. query .. "\nError: " .. tostring(results));
		connection:Disconnect();
		connection:Dispose();
		return false;
	end
	
	return results;
end

function Debugger(str) -- Used for debugging to make the info I need easier to find in the log.

str = "\n____________________________________________________________________________________________________________________________________________\n\n\n" .. str .. "\n\n____________________________________________________________________________________________________________________________________________\n";

LogDebug(str);

return;

end

function OnError(errorArgs)
	Debugger("Oh no! In Stacks Searching Report had a problem! Error: " .. tostring(errorArgs));
end