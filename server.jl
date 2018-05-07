using Joseki, JSON, PyCall
@pyimport lxml.etree as etree

### Create some endpoints

# This function takes two numbers x and y from the query string and returns x^y
# In this case they need to be identified by name and it should be called with
# something like 'http://localhost:8000/pow/?x=2&y=3'

function validateXML(xml_path::String, xsd_path::String)
    xmlschema_doc = etree.parse(xsd_path)
    
    xmlschema = etree.XMLSchema(xmlschema_doc)
    try
        xml_doc = etree.parse(xml_path)
    catch
        return -1 #xml mal formado
    end
    result = xmlschema[:validate](xml_doc)

    return result #true valido, false invalido
end

function consultar(req::HTTP.Request)
    j = HTTP.queryparams(HTTP.URI(req.target))
    if !(haskey(j, "x")&haskey(j, "y"))
        return error_responder(req, "You need to specify values for x and y!")
    end
    # Try to parse the values as numbers.  If there's an error here the generic
    # error handler will deal with it.
    x = parse(Float32, j["x"])
    y = parse(Float32, j["y"])
    result = validateXML("shiporder.xml","shiporder.xsd")
    print(result)
    json_responder(req, result) #mudar para responder xml
end

# This function takes two numbers n and k from a JSON-encoded request
# body and returns binomial(n, k)
function submeter(req::HTTP.Request)
   #logica aqui
end

### Create and run the server

# Make a router and add routes for our endpoints.
endpoints = [
    (consultar, "GET", "/"),
    (submeter, "POST", "/")
]
s = Joseki.server(endpoints)

# Fire up the server
HTTP.serve(s, ip"127.0.0.1", 8002; verbose=false)