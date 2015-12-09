function parse(s)
	 return read_from_tokens(tokenize(s))
end

function tokenize(s)
	 s = s:gsub("%(", " ( ")
	 s = s:gsub("%)", " ) ")
	 t = {}
	 for w in s:gmatch("%S+") do table.insert(t, w) end
	 return t
end

function read_from_tokens(tokens)

	 if #tokens == 0 then
			error('unexpected EOF while reading')
	 end

	 token = table.remove(tokens, 1)

	 if token == "(" then
			l = {}
			while tokens[1] ~= ')' do
				 table.insert(l, read_from_tokens(tokens))
			end
			table.remove(tokens, 1)
			return l
	 elseif token == ')' then
			error('Unexpected closing paren')
	 else
			return atom(token)
	 end

end

function atom(token)
	 n = tonumber(token)
	 if not n then
			return {content = token, type = "symbol"}
	 else
			return n
	 end
end


function Env(o)
	 return {inner = {}, outer = o}
end

function Env_find(e, var)
	 if e['inner'][var] ~= nil then
			return e
	 else
			return Env_find(e['outer'], var)
	 end
end

function Procedure(params, body, env)
	 local e = Env(env)
	 return function (...)
			for i = 1, #params do
				 e.inner[params[i]] = arg[i]
			end
			return eval(body, e)
	 end
end

function eval(x, env)

	 if type(x) ~= "table" then
			return x
	 end
	 if x.type == "symbol" then
			return Env_find(env, x.content).inner[x.content]
	 end
	 x[1] = x[1].content

	 if x[1] == "quote" then
			table.remove(x, 1)
			return x
	 elseif x[1] == "if" then
			if eval(x[1], env) then
				 return eval(x[2], env)
			else
				 return eval(x[3], env)
			end
	 elseif x[1] == "define" then
			local var = x[2].content
			local exp = x[3]
			env.inner[var] = eval(exp, env)
	 elseif x[1]  == "set!" then
			local var = x[2]
			local exp = x[3]
			Env_find(env, var).inner[var] = eval(exp, var)
	 elseif x[1] == "lambda" then
			local params = x[2]
			local body   = x[3]
			return Procedure(params, body, env)
	 else
			local proc = eval(x[1], env)
			local args = {}
			for i = 2, #x do
				 table.insert(args, eval(x[i], env))
			end
			proc(unpack(args))
	 end
end


function repl()
	 io.write("> ")
	 local env = Env({})
	 while true do
			local s = eval(parse(io.read()), env)
			print(s)
			io.write("> ")
	 end
end

repl()
