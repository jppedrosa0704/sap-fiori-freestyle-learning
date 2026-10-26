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


  method OVCABSET_GET_ENTITY.
    er_entity-ordemid = 1.
    er_entity-criadopor = 'João Paulo'.
    er_entity-datacriacao = '19700101000000'.
  endmethod.


  method OVCABSET_GET_ENTITYSET.

  endmethod.


  method OVCABSET_UPDATE_ENTITY.

  endmethod.


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


  method OVITEMSET_GET_ENTITY.

  endmethod.


  method OVITEMSET_GET_ENTITYSET.

  endmethod.


  method OVITEMSET_UPDATE_ENTITY.

  endmethod.
ENDCLASS.
