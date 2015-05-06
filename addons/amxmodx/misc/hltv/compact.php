<?php
	function ZipCompressFile($Origem, $Destino, $Arquivo, $Nivel = false)
	{
		$Caminho = $Destino . $Arquivo . '.zip';
		$Modo = 'wb' . $Nivel;
		
		$Erro = false;
		
		if($Saida = gzopen($Caminho, $Modo))
		{
			if($Entrada = fopen($Origem . $Arquivo,'rb'))
			{
				while(!feof($Entrada))
				{
					gzwrite($Saida, fread($Entrada, 1024 * 512));
				}
				
				fclose($Entrada);
			}
			else
			{
				$Erro = true;
			}
			
			gzclose($Saida);
		}
		else
		{
			$Erro = true;
		}
		
		if($Erro)
		{
			echo "Falha ao copiar " . $Origem . $Arquivo . " para " . $Caminho;
			
			return false;
		}
		else
		{
			echo "Movido " . $Origem . $Arquivo . " para " . $Caminho;
			
			return $Caminho;
		}
	}

	// Demos Dir
	$DemosHLTV = '/home/hltv/hltv1/cstrike/demos/';
	
	// WWW Dir
	$DirWWW = '/var/www/html/demos/';

	$Handler = opendir($DemosHLTV);
	
	if($Handler)
	{
		while(false !== ($Falha = readdir($Handler)))
		{
			if(preg_match("/(.*).dem/", $Falha, $Demo))
			{
				ZipCompressFile($DemosHLTV, $DirWWW, $Falha);
			}
		}
		
		foreach(glob($DemosHLTV . "*.dem") as $ArquivoDEM)
		{
			unlink($ArquivoDEM);
		}
		
		closedir($Handler);
	}
?>