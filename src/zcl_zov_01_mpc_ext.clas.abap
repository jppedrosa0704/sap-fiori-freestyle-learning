class ZCL_ZOV_01_MPC_EXT definition
  public
  inheriting from ZCL_ZOV_01_MPC
  create public .

public section.

  types:
    BEGIN OF ty_ordem_item,
          OrdemId      TYPE I,
          DataCriacao  TYPE TIMESTAMP,
          CriadoPor    TYPE C LENGTH 20,
          ClienteId    TYPE I,
          TotalItens   TYPE P LENGTH 8 DECIMALS 2,
          TotalFrete   TYPE P LENGTH 8 DECIMALS 2,
          TotalOrdem   TYPE P LENGTH 8 DECIMALS 2,
          Status       TYPE C LENGTH 1,
         ToOVItem TYPE TABLE OF ts_ovitem WITH DEFAULT KEY,
        END OF ty_ordem_item .

  class-methods CLASS_CONSTRUCTOR .

  methods DEFINE
    redefinition .
protected section.
private section.
ENDCLASS.



CLASS ZCL_ZOV_01_MPC_EXT IMPLEMENTATION.


  method CLASS_CONSTRUCTOR.
  endmethod.


METHOD DEFINE.
  DATA: lo_entity_type TYPE REF TO /iwbep/if_mgw_odata_entity_typ.

  super->DEFINE( ).

  lo_entity_type = model->get_entity_type( iv_entity_name = 'OVCab' ).
  lo_entity_type->bind_structure(  iv_structure_name = 'ZCL_ZOV_01_MPC_EXT=>TY_ORDEM_ITEM' ).

ENDMETHOD.
ENDCLASS.
