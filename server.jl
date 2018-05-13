using Joseki, JSON, PyCall, HTTP, LightXML
@pyimport lxml.etree as etree

function response(req,code,methodName)
    req.response.body = "<methodReturn>
                                            <methodName>$methodName</methodName>
                                            <value>$code</value>
                                        </methodReturn>"
    return req.response
end

function validateXML(xml_doc, xsd_path::String)
    xmlschema_doc = etree.parse(xsd_path)
    
    xmlschema = etree.XMLSchema(xmlschema_doc)

    result = xmlschema[:validate](xml_doc)

    return result #true valido, false invalido
end

#consulta o status da inscrição do candidato com o CPF informado como parâmetro. 
#Possíveis retornos: 0 - Candidato não encontrado, 1 - Em processamento, 
#2 - Candidato Aprovado e Selecionado, 3 - Candidato Aprovado e em Espera, 4 - Candidato Não Aprovado.

function consultarStatus(req::HTTP.Request)
    
    req.response.headers[3] = "Content-Type" => "text/xml; charset=utf-8"
    j = HTTP.queryparams(HTTP.URI(req.target))
    xml = " "
    for key in keys(j)
        xml = key
    end
    
    try
        xml_doc = etree.fromstring(xml)
        result = validateXML(xml_doc,"request.xml")
        
        if result == false
            return response(req,-1,"consultarStatus") # xml invalido 
        else
            try
                nomeMetodo = xml_doc[:find](".//methodName")[:text]
                if nomeMetodo != "consultarStatus"
                    return response(req,-1,"consultarStatus") #xml invalido
                else  
                    cpf = xml_doc[:find](".//cpf")[:text]
                    if cpf == "00000000000"
                        return response(req,0,"consultarStatus")
                    elseif cpf == "00000000001"
                        return response(req,1,"consultarStatus")
                    elseif cpf == "00000000002"
                        return response(req,2,"consultarStatus")
                    elseif cpf == "00000000003"
                        return response(req,3,"consultarStatus")
                    elseif cpf == "00000000004"
                        return response(req,4,"consultarStatus")
                    else
                        return response(req,0,"consultarStatus") #cpf nao encontrado
                    end 

                end
            catch
                return response(req,-1,"consultarStatus") #xml invalido
            end
        end
    catch
        return response(req,-2,"consultarStatus") #xml mal formado
    end
end

#envia um boletim como parâmetro e retorna um número inteiro 
#(0 - sucesso, 1 - XML inválido, 2 - XML mal-formado, 3 - Erro Interno)

function submeter(req::HTTP.Request)
    req.response.headers[3] = "Content-Type" => "text/xml; charset=utf-8"
    try
        xml_doc = etree.fromstring(String(req.body))
        try
            result = validateXML(xml_doc,"request.xml")
            if result == false
                return response(req,1,"submeter") # xml invalido 
            else
                try
                    nomeMetodo = xml_doc[:find](".//methodName")[:text]
                    if nomeMetodo != "submeter"
                        return response(req,1,"submeter") #xml invalido
                    else
                        try
                            alun = xml_doc[:find](".//aluno")[:text]
                        catch
                            return response(req,1,"submeter") #xml invalido, tentou passar xml da consulta
                        end     
                            return response(req,0,"submeter") #sucesso
                        
                    end
                catch
                    return response(req,3,"submeter") # erro interno 
                end
            end
        catch
            return response(req,3,"submeter") # erro interno 
        end
    catch
        return response(req,2,"submeter") #xml mal formado
    end
end


### Create and run the server

# Make a router and add routes for our endpoints.
endpoints = [
    (consultarStatus, "GET", "/"),
    (submeter, "POST", "/")
]
s = Joseki.server(endpoints)

# Fire up the server
HTTP.serve(s, ip"127.0.0.1", 8002; verbose=false)