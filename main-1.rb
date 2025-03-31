require 'date'

class ListaAfazeres
  def initialize
    @regex_horario = /(?:às\s+)?(\d{1,2}(?:[\s:](\d{2}))?(?:\s*[hH]((ora)?s?)(\s)?)?(\d{2})?(?:\s*[mM]((inuto)?s?)?)?)/
    
    @regex_data_relativa = /\b(hoje|amanhã|depois\s+de\s+amanhã)\b/
    @regex_data_numerica = /\b(?:dia\s+)?(\d{1,2})[\/\s]+(?:de\s+)?(?!dia)([a-zç]+|\d{1,2})[\/\s]+(?:de\s+)?(\d{2,4})?\b/
    
    @regex_pessoas = /(?:com|para)\s+([A-Z][a-zá-úÁ-Ú]+(?:\s+e\s+[A-Z][a-zá-úÁ-Ú]+|\s+[A-Z][a-zá-úÁ-Ú]+)*)/
    
    @regex_tags = /(#\w+)/
    
    @regex_acoes = /\b(agendar|marcar|ligar|reunir|reunião|\w+r)\b/
    
    @regex_email = /([a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+)/
    @regex_url = /(https?:\/\/[^\s]+)|((www.)?\w+.com)/
    
    @meses = {
      'janeiro' => 1, 'fevereiro' => 2, 'março' => 3, 'abril' => 4,
      'maio' => 5, 'junho' => 6, 'julho' => 7, 'agosto' => 8,
      'setembro' => 9, 'outubro' => 10, 'novembro' => 11, 'dezembro' => 12,
      'jan' => 1, 'fev' => 2, 'mar' => 3, 'abr' => 4, 'mai' => 5, 'jun' => 6,
      'jul' => 7, 'ago' => 8, 'set' => 9, 'out' => 10, 'nov' => 11, 'dez' => 12
    }
  end

  def extrair_horario(horario_texto)
    return "00:00" if !horario_texto
      
    horario_texto = horario_texto.gsub('às', '').strip
    
    if horario_texto.include?(':')
      hora, minuto = horario_texto.split(':')
      minuto = minuto.gsub(/[^\d].*/, '') if minuto
    elsif horario_texto.include?(' ')
      partes = horario_texto.split
      hora = partes[0]
      minuto = partes.length > 1 && partes[1] =~ /^\d+$/ ? partes[1] : "00"
    else
      hora = horario_texto.gsub('horas', '').gsub('hora', '').strip
      minuto = "00"
    end

    hora = hora.gsub(/[^\d]/, '')
    
    format("%02d:%02d", hora.to_i, minuto.to_i)
  end

  def extrair_data(texto)
    hoje = Date.today
    match_relativa = texto.match(@regex_data_relativa)
    
    if match_relativa
      termo = match_relativa[1].downcase
      if termo.include?('hoje')
        return hoje.strftime('%d/%m/%Y')
      elsif termo.include?('amanhã') && !termo.include?('depois')
        return (hoje + 1).strftime('%d/%m/%Y')
      elsif termo.include?('depois') && termo.include?('amanhã')
        return (hoje + 2).strftime('%d/%m/%Y')
      end
    end
    
    match_numerica = texto.match(@regex_data_numerica)
    if match_numerica
      dia = match_numerica[1].to_i

      mes_texto = match_numerica[2].downcase
      if mes_texto =~ /^\d+$/
        mes = mes_texto.to_i
      else
        mes = hoje.month
        @meses.each do |nome_mes, num_mes|
          if nome_mes.include?(mes_texto) || mes_texto.include?(nome_mes)
            mes = num_mes
            break
          end
        end
      end
      
      if match_numerica[3]
        ano_texto = match_numerica[3]
        if ano_texto.length == 2
          ano = "20#{ano_texto}".to_i
        else
          ano = ano_texto.to_i
        end
      else
        ano = hoje.year
      end
      
      return format("%02d/%02d/%d", dia, mes, ano)
    end
    
    hoje.strftime('%d/%m/%Y')
  end

  def extrair_pessoas(texto)
    match = texto.match(@regex_pessoas)
    if match
      pessoas_texto = match[1]
      pessoas = pessoas_texto.split(/\s+e\s+|\s*,\s*/)
      return pessoas.map(&:strip).reject(&:empty?)
    end
    nil
  end

  def extrair_informacoes(texto)
    horario_match = texto.match(@regex_horario)
    tag_matches = texto.scan(@regex_tags)
    acao_match = texto.match(@regex_acoes)
    email_match = texto.match(@regex_email)
    url_match = texto.match(@regex_url)
    pessoas = extrair_pessoas(texto)
    
    data = extrair_data(texto)

    informacoes = {
      'Dia' => data,
      'Horário' => extrair_horario(horario_match ? horario_match[0] : nil),
      'Pessoa' => pessoas ? pessoas.join(', ') : nil,
      'Ação' => acao_match ? acao_match[1] : nil,
      'Tags' => tag_matches.empty? ? nil : tag_matches.join(' '),
      'Email' => email_match ? email_match[1] : nil,
      'URL' => url_match ? url_match[1] : nil
    }

    informacoes
  end
end

atividade = ListaAfazeres.new

mensagem = "Agendar com José reunião às 10:00 amanhã #trabalho"
resultado = atividade.extrair_informacoes(mensagem)

puts "Mensagem original:\n"
puts mensagem

puts "\nResumo:"
resultado.each do |chave, valor|
  puts "#{chave}: #{valor}" if valor
end