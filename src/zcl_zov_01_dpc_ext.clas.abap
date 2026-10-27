class ZCL_ZOV_01_DPC_EXT definition
  public
  inheriting from ZCL_ZOV_01_DPC
  create public .

public section.
protected section.

  methods MENSAGEMSET_CREATE_ENTITY
    redefinition .
  methods MENSAGEMSET_DELETE_ENTITY
    redefinition .
  methods MENSAGEMSET_GET_ENTITY
    redefinition .
  methods MENSAGEMSET_GET_ENTITYSET
    redefinition .
  methods MENSAGEMSET_UPDATE_ENTITY
    redefinition .
  methods OVCABSET_CREATE_ENTITY
    redefinition .
  methods OVCABSET_DELETE_ENTITY
    redefinition .
  methods OVCABSET_GET_ENTITY
    redefinition .
  methods OVCABSET_GET_ENTITYSET
    redefinition .
  methods OVCABSET_UPDATE_ENTITY
    redefinition .
  methods OVITEMSET_CREATE_ENTITY
    redefinition .
  methods OVITEMSET_DELETE_ENTITY
    redefinition .
  methods OVITEMSET_GET_ENTITY
    redefinition .
  methods OVITEMSET_GET_ENTITYSET
    redefinition .
  methods OVITEMSET_UPDATE_ENTITY
    redefinition .
private section.
ENDCLASS.



CLASS ZCL_ZOV_01_DPC_EXT IMPLEMENTATION.


  method MENSAGEMSET_CREATE_ENTITY.

  endmethod.


  method MENSAGEMSET_DELETE_ENTITY.

  endmethod.


  method MENSAGEMSET_GET_ENTITY.

  endmethod.


  method MENSAGEMSET_GET_ENTITYSET.

  endmethod.


  method MENSAGEMSET_UPDATE_ENTITY.

  endmethod.


METHOD ovcabset_create_entity.

  " Variável para guardar o último ORDEMID encontrado
  DATA: ld_lastid TYPE int4.

  " Estrutura da tabela ZOVCAB que será utilizada para gravar os dados
  DATA: ls_cab TYPE zovcab.

  " Obtém o contentor de mensagens do SAP Gateway
  " Será utilizado caso seja necessário devolver erros ao frontend
  DATA(lo_msg) = me->/iwbep/if_mgw_conv_srv_runtime~get_message_container( ).

  " Lê os dados enviados na requisição OData (POST)
  " e coloca-os na estrutura ER_ENTITY
  io_data_provider->read_entry_data(
    IMPORTING
      es_data = er_entity
  ).

  " Copia os campos com o mesmo nome de ER_ENTITY para LS_CAB
  MOVE-CORRESPONDING er_entity TO ls_cab.

  " Preenche automaticamente os campos de auditoria
  ls_cab-criacao_data    = sy-datum.  " Data atual
  ls_cab-criacao_hora    = sy-uzeit.  " Hora atual
  ls_cab-criacao_usuario = sy-uname.  " Utilizador atual

  " Procura o maior ORDEMID existente na tabela
  SELECT SINGLE MAX( ordemid )
    INTO ld_lastid
    FROM zovcab.

  " Gera o próximo ORDEMID
  ls_cab-ordemid = ld_lastid + 1.

  " Insere o novo registo na tabela ZOVCAB
  INSERT zovcab FROM ls_cab.

  " Verifica se ocorreu algum erro durante o INSERT
  IF sy-subrc <> 0.

    " Adiciona uma mensagem de erro ao contentor do Gateway
    lo_msg->add_message_text_only(
      EXPORTING
        iv_msg_type = 'E'
        iv_msg_text = 'Erro ao inserir ordem'
    ).

    " Lança uma exceção para devolver o erro ao consumidor OData
    RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
      EXPORTING
        message_container = lo_msg.

  ENDIF.

  " Copia os dados gravados para a entidade de resposta
  " Assim o frontend recebe o ORDEMID gerado
  MOVE-CORRESPONDING ls_cab TO er_entity.

  " Converte a data e hora de criação para um timestamp
  CONVERT
    DATE ls_cab-criacao_data
    TIME ls_cab-criacao_hora
    INTO TIME STAMP er_entity-datacriacao
    TIME ZONE sy-zonlo.

ENDMETHOD.


  method OVCABSET_DELETE_ENTITY.

  endmethod.


METHOD ovcabset_get_entity.

  " Variável para armazenar o ID da ordem recebido na URL
  DATA: ld_ordemid TYPE zovcab-ordemid.

  " Estrutura para armazenar uma linha da tabela de chaves recebidas
  DATA: ls_key_tab LIKE LINE OF it_key_tab.

  " Estrutura para armazenar os dados do cabeçalho da ordem
  DATA: ls_cab TYPE zovcab.

  " Obtém o container de mensagens do Gateway
  DATA(lo_msg) = me->/iwbep/if_mgw_conv_srv_runtime~get_message_container( ).

  "====================================================================
  " Leitura do parâmetro de entrada (chave da entidade)
  "====================================================================

  " Procura na tabela de chaves o parâmetro chamado 'OrdemId'
  READ TABLE it_key_tab INTO ls_key_tab WITH KEY name = 'OrdemId'.

  " Se a chave não foi encontrada
  IF sy-subrc <> 0.

    " Adiciona mensagem de erro ao container
    lo_msg->add_message_text_only(
      EXPORTING
        iv_msg_type = 'E'
        iv_msg_text = 'Id da ordem não informado'
    ).

    " Dispara exceção de negócio para retornar erro ao consumidor OData
    RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
      EXPORTING
        message_container = lo_msg.

  ENDIF.

  " Armazena o valor da chave recebida
  ld_ordemid = ls_key_tab-value.

  "====================================================================
  " Busca da ordem na tabela ZOVCAB
  "====================================================================

  " Busca os dados da ordem informada
  SELECT SINGLE *
    INTO ls_cab
    FROM zovcab
   WHERE ordemid = ld_ordemid.

  " Se encontrou a ordem
  IF sy-subrc = 0.

    " Copia os campos com nomes iguais da estrutura ls_cab
    " para a entidade de saída do serviço OData
    MOVE-CORRESPONDING ls_cab TO er_entity.

    " Preenche manualmente o campo CriadoPor
    er_entity-criadopor = ls_cab-criacao_usuario.

    " Converte data e hora SAP para timestamp UTC
    CONVERT DATE ls_cab-criacao_data
            TIME ls_cab-criacao_hora
       INTO TIME STAMP er_entity-datacriacao
       TIME ZONE 'UTC'.  " Pode ser alterado para sy-zonlo se necessário

  ELSE.

    " Se a ordem não foi encontrada, adiciona mensagem de erro
    lo_msg->add_message_text_only(
      EXPORTING
        iv_msg_type = 'E'
        iv_msg_text = 'Id da ordem não encontrado'
    ).

    " Dispara exceção para retornar erro ao consumidor OData
    RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
      EXPORTING
        message_container = lo_msg.

  ENDIF.

ENDMETHOD.


METHOD ovcabset_get_entityset.

  " Tabela interna para armazenar os registos retornados da ZOVCAB
  DATA: lt_cab TYPE STANDARD TABLE OF zovcab.

  " Estrutura de trabalho para percorrer os registos da ZOVCAB
  DATA: ls_cab TYPE zovcab.

  " Estrutura correspondente a uma linha da entidade de saída
  DATA: ls_entityset LIKE LINE OF et_entityset.

  " Tabela utilizada para montar dinamicamente o ORDER BY
  DATA: lt_orderby TYPE STANDARD TABLE OF string.

  " String final contendo a cláusula ORDER BY
  DATA: ld_orderby TYPE string.

  "====================================================================
  " Montagem dinâmica da cláusula ORDER BY
  "====================================================================

  " Percorre os campos de ordenação enviados pelo consumidor OData
  LOOP AT it_order INTO DATA(ls_order).

    " Converte o nome da propriedade para maiúsculas
    TRANSLATE ls_order-property TO UPPER CASE.

    " Converte o tipo de ordenação para maiúsculas
    TRANSLATE ls_order-order TO UPPER CASE.

    " Ajusta o valor conforme a sintaxe esperada pelo ABAP Open SQL
    IF ls_order-order = 'DESC'.

      ls_order-order = 'DESCENDING'.

    ELSE.

      ls_order-order = 'ASCENDING'.

    ENDIF.

    " Monta uma linha de ordenação
    " Exemplo:
    " ORDEMID ASCENDING
    " DATA_CRIACAO DESCENDING
    APPEND |{ ls_order-property } { ls_order-order }|
        TO lt_orderby.

  ENDLOOP.

  " Concatena todas as regras de ordenação numa única string
  " Exemplo:
  " ORDEMID ASCENDING, DATACRIACAO DESCENDING
  CONCATENATE LINES OF lt_orderby
         INTO ld_orderby
    SEPARATED BY ', '.

  "====================================================================
  " Define ordenação padrão caso nenhuma tenha sido enviada
  "====================================================================

  IF ld_orderby = ''.

    " Ordenação obrigatória para evitar erro em paginação
    ld_orderby = 'OrdemId ASCENDING'.

  ENDIF.

* Código antigo sem paginação
*
* SELECT *
*   INTO TABLE lt_cab
*   FROM zovcab
*   WHERE (iv_filter_string)
*   ORDER BY (ld_orderby).

  "====================================================================
  " Consulta da tabela utilizando filtros, ordenação e paginação
  "====================================================================

  SELECT *
    FROM zovcab
    WHERE (iv_filter_string)
    ORDER BY (ld_orderby)
    INTO TABLE @lt_cab
    UP TO @is_paging-top ROWS
    OFFSET @is_paging-skip.

  "====================================================================
  " Conversão dos dados da tabela para a entidade OData
  "====================================================================

  LOOP AT lt_cab INTO ls_cab.

    " Limpa a estrutura de saída
    CLEAR ls_entityset.

    " Copia os campos de mesmo nome da estrutura SAP
    " para a estrutura da entidade OData
    MOVE-CORRESPONDING ls_cab TO ls_entityset.

    " Preenchimento manual de campos específicos
    ls_entityset-criadopor = ls_cab-criacao_usuario.

    " Converte Data + Hora SAP para Timestamp
    CONVERT
      DATE ls_cab-criacao_data
      TIME ls_cab-criacao_hora
      INTO TIME STAMP ls_entityset-datacriacao
      TIME ZONE sy-zonlo.

    " Adiciona o registo à tabela de retorno do serviço
    APPEND ls_entityset TO et_entityset.

  ENDLOOP.

ENDMETHOD.


METHOD ovcabset_update_entity.

  " Obtém o container de mensagens do SAP Gateway
  " Será utilizado para devolver mensagens de erro ao consumidor OData
  DATA(lo_msg) = me->/iwbep/if_mgw_conv_srv_runtime~get_message_container( ).

  "====================================================================
  " Leitura dos dados enviados no corpo (payload) da requisição HTTP
  "====================================================================

  " Converte automaticamente o payload JSON/XML recebido
  " para a estrutura da entidade OData
  io_data_provider->read_entry_data(
    IMPORTING
      es_data = er_entity
  ).

  "====================================================================
  " Leitura da chave da URL
  "====================================================================

  " Recupera o valor da chave OrdemId enviada na URL
  " Exemplo:
  " /OVCabSet('1001')
  "
  " Como normalmente a chave não é enviada no payload,
  " garantimos que ela é preenchida a partir da URL
  er_entity-ordemid = it_key_tab[ name = 'OrdemId' ]-value.

  "====================================================================
  " Atualização do registro na tabela ZOVCAB
  "====================================================================

  " Atualiza os campos da ordem na base de dados
  UPDATE zovcab
    SET clienteid = er_entity-clienteid
        totalitens = er_entity-totalitens
        totalfrete = er_entity-totalfrete
        totalordem = er_entity-totalordem
        status     = er_entity-status
    WHERE ordemid = er_entity-ordemid.

  "====================================================================
  " Validação da atualização
  "====================================================================

  " Se ocorreu algum erro durante a atualização
  IF sy-subrc <> 0.

    " Adiciona mensagem de erro ao container
    lo_msg->add_message_text_only(
      EXPORTING
        iv_msg_type = 'E'
        iv_msg_text = 'Erro ao atualizar ordem'
    ).

    " Dispara exceção de negócio para devolver
    " a mensagem ao consumidor do serviço OData
    RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
      EXPORTING
        message_container = lo_msg.

  ENDIF.

ENDMETHOD.


  method OVITEMSET_CREATE_ENTITY.
    DATA: ls_item TYPE zovitem.

    DATA(lo_msg) = me->/iwbep/if_mgw_conv_srv_runtime~get_message_container( ).

    IO_DATA_PROVIDER->read_entry_data(
      IMPORTING
      es_data = er_entity
    ).

    MOVE-CORRESPONDING er_entity TO ls_item.

    IF er_entity-ITEMID = 0.
      SELECT SINGLE MAX( itemid )
        INTO er_entity-itemid
        FROM zovitem
        WHERE ordemid = er_entity-ordemid.

      er_entity-itemid = er_entity-itemid + 1.

    ENDIF.

    INSERT zovitem FROM ls_item.
    IF sy-subrc <> 0.
      lo_msg->add_message_text_only(
        EXPORTING
          iv_msg_type = 'E'
          iv_msg_text = 'Erro ao inserir o item'
      ).

      RAISE EXCEPTION TYPE /IWBEP/CX_MGW_BUSI_EXCEPTION
        EXPORTING
          message_container = lo_msg.

    ENDIF.



  endmethod.


  method OVITEMSET_DELETE_ENTITY.

  endmethod.


METHOD ovitemset_get_entity.

  " Estrutura para armazenar cada chave recebida na chamada OData
  DATA: ls_key_tab LIKE LINE OF it_key_tab.

  " Estrutura para armazenar os dados do item da ordem
  DATA: ls_item TYPE zovitem.

  " Flag utilizada para indicar se ocorreu algum erro de validação
  DATA: ld_error TYPE flag.

  " Obtém o container de mensagens do SAP Gateway
  DATA(lo_msg) = me->/iwbep/if_mgw_conv_srv_runtime~get_message_container( ).

  "====================================================================
  " Validação dos parâmetros de entrada
  "====================================================================

  " Procura o parâmetro OrdemId nas chaves recebidas
  READ TABLE it_key_tab INTO ls_key_tab WITH KEY name = 'OrdemId'.

  " Se não encontrou o parâmetro
  IF sy-subrc <> 0.

    " Marca que ocorreu erro
    ld_error = 'X'.

    " Adiciona mensagem de erro ao container
    lo_msg->add_message_text_only(
      EXPORTING
        iv_msg_type = 'E'
        iv_msg_text = 'Id da ordem não informado'
    ).

  ENDIF.

  " Armazena o valor recebido da OrdemId
  ls_item-ordemid = ls_key_tab-value.

  " Procura o parâmetro ItemId nas chaves recebidas
  READ TABLE it_key_tab INTO ls_key_tab WITH KEY name = 'ItemId'.

  " Se não encontrou o parâmetro
  IF sy-subrc <> 0.

    " Marca que ocorreu erro
    ld_error = 'X'.

    " Adiciona mensagem de erro ao container
    lo_msg->add_message_text_only(
      EXPORTING
        iv_msg_type = 'E'
        iv_msg_text = 'Id do item não informado'
    ).

  ENDIF.

  " Armazena o valor recebido do ItemId
  ls_item-itemid = ls_key_tab-value.

  "====================================================================
  " Se existiu algum erro de validação, interrompe o processamento
  "====================================================================

  IF ld_error = 'X'.

    " Lança exceção de negócio contendo todas as mensagens acumuladas
    RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
      EXPORTING
        message_container = lo_msg.

  ENDIF.

  "====================================================================
  " Pesquisa do item na tabela ZOVITEM
  "====================================================================

  " Procura o item da ordem através da chave composta
  " (OrdemId + ItemId)
  SELECT SINGLE *
    INTO ls_item
    FROM zovitem
   WHERE ordemid = ls_item-ordemid
     AND itemid  = ls_item-itemid.

  " Se o registo foi encontrado
  IF sy-subrc = 0.

    " Copia automaticamente os campos com nomes iguais
    " para a entidade de retorno do serviço OData
    MOVE-CORRESPONDING ls_item TO er_entity.

  ELSE.

    " Adiciona mensagem de erro ao container
    lo_msg->add_message_text_only(
      EXPORTING
        iv_msg_type = 'E'
        iv_msg_text = 'Item não encontrado'
    ).

    " Lança exceção para devolver a mensagem ao consumidor OData
    RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
      EXPORTING
        message_container = lo_msg.

  ENDIF.

ENDMETHOD.


method OVITEMSET_GET_ENTITYSET.
  DATA: ld_ordemid       TYPE int4.
  DATA: lt_ordemid_range TYPE RANGE OF int4.
  DATA: ls_ordemid_range LIKE LINE OF lt_ordemid_range.
  DATA: ls_key_tab       LIKE LINE OF it_key_tab.

  " input
  READ TABLE it_key_tab INTO ls_key_tab WITH KEY name = 'OrdemId'.
  IF sy-subrc = 0.
    ld_ordemid = ls_key_tab-value.

    CLEAR ls_ordemid_range.
    ls_ordemid_range-sign   = 'I'.
    ls_ordemid_range-option = 'EQ'.
    ls_ordemid_range-low    = ld_ordemid.
    APPEND ls_ordemid_range TO lt_ordemid_range.
  ENDIF.

  SELECT *
    INTO CORRESPONDING FIELDS OF TABLE et_entityset
    FROM zovitem
   WHERE ordemid IN lt_ordemid_range.
endmethod.


METHOD ovitemset_update_entity.

  " Obtém o container de mensagens do Gateway
  DATA(lo_msg) = me->/iwbep/if_mgw_conv_srv_runtime~get_message_container( ).

  " Lê os dados enviados no body da requisição (PUT/MERGE)
  io_data_provider->read_entry_data(
    IMPORTING
      es_data = er_entity
  ).

  " Recupera as chaves enviadas na URL
  er_entity-ordemid = it_key_tab[ name = 'OrdemId' ]-value. " Id da ordem
  er_entity-itemid  = it_key_tab[ name = 'ItemId'  ]-value. " Id do item

  " Recalcula o preço total do item
  er_entity-precotot = er_entity-quantidade * er_entity-precouni.

  " Atualiza os dados do item na tabela ZOVITEM
  UPDATE zovitem
    SET material   = er_entity-material     " Código do material
        descricao  = er_entity-descricao    " Descrição do item
        quantidade = er_entity-quantidade   " Quantidade solicitada
        precouni   = er_entity-precouni     " Preço unitário
        precotot   = er_entity-precotot     " Preço total calculado
    WHERE ordemid = er_entity-ordemid      " Ordem a atualizar
          AND itemid = er_entity-itemid.

  " Verifica se ocorreu erro na atualização
  IF sy-subrc <> 0.

    " Adiciona mensagem de erro ao retorno OData
    lo_msg->add_message_text_only(
      EXPORTING
        iv_msg_type = 'E'
        iv_msg_text = 'Erro ao atualizar o item'
    ).

    " Lança exceção para devolver a mensagem ao consumidor do serviço
    RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
      EXPORTING
        message_container = lo_msg.

  ENDIF.

ENDMETHOD.
ENDCLASS.
