*&---------Developing Solutions off people, process and project's-------
*& &
*& & Author...........: Christopher Nicolas Mauricio .'.
*& & Consultancy .....: DS3P
*& & Date develop ....: 10.07.2019
*& & Type of prg .....: Executable
*& & Transaction .....:
*&----------------------------------------------------------------------

REPORT yds3p_backup_table.

*&----------------------------------------------------------------------
*& Tabelas
*&----------------------------------------------------------------------
TABLES: dd02t,
        dd03l.
*&----------------------------------------------------------------------
*& Tipos
*&----------------------------------------------------------------------
TYPES: BEGIN OF typ_sel_table,
         sign   TYPE sign,
         option TYPE option,
         low    TYPE dd03l-tabname,
         high   TYPE dd03l-tabname,
       END OF typ_sel_table.
TYPES:  BEGIN OF ty_message,
          msgty TYPE message-msgty,      " Tipo da mensagem
          msgno TYPE message-msgno,      " Numero da mensagem
          msgtx TYPE message-msgtx,      " Descrição da mensagem
        END OF   ty_message.
*&----------------------------------------------------------------------
*& Estruturas
*&----------------------------------------------------------------------
DATA:    ls_return TYPE ty_message.
*&----------------------------------------------------------------------
*& Tabela Interna
*&----------------------------------------------------------------------
DATA:   lt_return TYPE STANDARD TABLE OF ty_message.
*&----------------------------------------------------------------------
*& Variáveis
*&----------------------------------------------------------------------

DATA: tabela TYPE c LENGTH 30,
      file   TYPE localfile.
DATA: go_alv     TYPE REF TO cl_salv_table.
DATA: v_table TYPE REF TO data.
DATA: lo_struct   TYPE REF TO cl_abap_structdescr,
      lo_element  TYPE REF TO cl_abap_elemdescr,
      lo_new_type TYPE REF TO cl_abap_structdescr,
      lo_new_tab  TYPE REF TO cl_abap_tabledescr,
      lo_data     TYPE REF TO data,
      lt_comp     TYPE cl_abap_structdescr=>component_table,
      lt_tot_comp TYPE cl_abap_structdescr=>component_table,
      la_comp     LIKE LINE OF lt_comp,
      lf_months   TYPE monat,
      lf_run_mon  TYPE monat.
*

*&----------------------------------------------------------------------
*& Tela de Seleção
*&----------------------------------------------------------------------
SELECTION-SCREEN BEGIN OF BLOCK blk_par WITH FRAME.
SELECT-OPTIONS: s_tabla FOR dd03l-tabname.
PARAMETERS: p_path LIKE rlgrap-filename
                   DEFAULT 'C:\TEMP\' OBLIGATORY.
*PARAMETERS:  P_BORRAR AS CHECKBOX.
SELECTION-SCREEN END OF BLOCK blk_par.

SELECTION-SCREEN BEGIN OF BLOCK blk_par2 WITH FRAME TITLE text-t01.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(10) text-001.
SELECTION-SCREEN POSITION 12.
PARAMETERS: p_grab RADIOBUTTON GROUP rad1 DEFAULT 'X'.    "Gravar
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(10) text-002.
SELECTION-SCREEN POSITION 12.
PARAMETERS: p_carg RADIOBUTTON GROUP rad1.                "Carregar
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN END OF BLOCK blk_par2.

*SELECTION-SCREEN BEGIN OF BLOCK blk_par5 WITH FRAME TITLE text-t03.
*PARAMETERS:  p_retm AS CHECKBOX.
*SELECTION-SCREEN END OF BLOCK blk_par5.


*&----------------------------------------------------------------------
*& Início da Seleção
*&----------------------------------------------------------------------
START-OF-SELECTION.

  FIELD-SYMBOLS: <ft_table>      TYPE table,
                 <fs_line>       TYPE any,
                 <fs_select_opt> TYPE typ_sel_table.




  LOOP AT s_tabla ASSIGNING <fs_select_opt>.

    CLEAR: lo_struct,
           lo_element,
           lo_new_type,
           lo_new_tab,
           lo_data,
           lt_comp,
           lt_tot_comp,
           la_comp.

    tabela = <fs_select_opt>-low.
    CONCATENATE p_path tabela '.DAT' INTO file.

    lo_struct ?= cl_abap_typedescr=>describe_by_name( tabela ).
    lt_comp  = lo_struct->get_components( ).
    APPEND LINES OF lt_comp TO lt_tot_comp.

    lo_new_type = cl_abap_structdescr=>create( lt_tot_comp ).

    lo_new_tab = cl_abap_tabledescr=>create(
                    p_line_type  = lo_new_type
                    p_table_kind = cl_abap_tabledescr=>tablekind_std
                    p_unique     = abap_false ).

    CREATE DATA v_table TYPE HANDLE lo_new_tab.

    ASSIGN v_table->* TO  <ft_table> .

    IF <ft_table> IS ASSIGNED.
      TRY .
          IF p_carg EQ 'X'."UPLOAD

            DATA: caminho TYPE localfile.

            CONCATENATE p_path tabela sy-datum sy-timlo '.DAT' INTO caminho.

            SELECT *& FROM (tabela) INTO TABLE <ft_table> .

            IF sy-subrc EQ 0.

              CALL FUNCTION 'WS_DOWNLOAD'
                EXPORTING
                  filename = caminho
                  filetype = 'DAT'
                TABLES
                  data_tab = <ft_table>.

              IF sy-subrc EQ 0.


                CALL FUNCTION 'WS_UPLOAD'
                  EXPORTING
                    filename = file
                    filetype = 'DAT'
                  TABLES
                    data_tab = <ft_table>.

                IF sy-subrc EQ 0.

                  MODIFY (tabela) FROM TABLE <ft_table> .

                  IF sy-subrc EQ 0.
                    CONCATENATE tabela ' Salva com sucesso' INTO tabela.
                    ls_return-msgno = '0'.
                    ls_return-msgtx = tabela.
                    ls_return-msgty = 'S'.
                    APPEND ls_return TO lt_return.
                  ELSE.
                    CONCATENATE 'Atenção erro ao salar dados na tabela '
                     tabela ' !' INTO tabela.
                    ls_return-msgno = sy-subrc.
                    ls_return-msgtx = tabela.
                    ls_return-msgty = 'E'.
                    APPEND ls_return TO lt_return.
                  ENDIF.
                ELSE.
                  CONCATENATE 'Atenção erro ao efetuar carregamento da tabela '
                  tabela ' !' INTO tabela.
                  ls_return-msgno = sy-subrc.
                  ls_return-msgtx = tabela.
                  ls_return-msgty = 'E'.
                  APPEND ls_return TO lt_return.
                ENDIF.
              ENDIF.
            ENDIF.


          ELSEIF p_grab EQ 'X'.

            SELECT * FROM (tabela) INTO TABLE <ft_table> .

            IF sy-subrc EQ 0.

              CALL FUNCTION 'WS_DOWNLOAD'
                EXPORTING
                  filename = file
                  filetype = 'DAT'
                TABLES
                  data_tab = <ft_table>.

              IF sy-subrc EQ 0.
                CONCATENATE tabela ' Salva com sucesso' INTO tabela.
                ls_return-msgno = '0'.
                ls_return-msgtx = tabela.
                ls_return-msgty = 'S'.
                APPEND ls_return TO lt_return.
              ELSE.
                ls_return-msgno = sy-subrc.
                ls_return-msgtx = 'Atenção erro ao efetuar procedimento'.
                ls_return-msgty = 'E'.
                APPEND ls_return TO lt_return.
              ENDIF.
            ELSE.
              CONCATENATE 'Não há dados na tabela ' tabela '!' INTO tabela.
              ls_return-msgno = sy-subrc.
              ls_return-msgtx = 'Não há dados na tabela'.
              ls_return-msgty = 'I'.
              APPEND ls_return TO lt_return.
            ENDIF.
          ENDIF.
      ENDTRY.
    ENDIF.
    UNASSIGN <ft_table>.
  ENDLOOP.
  IF NOT lt_return[] IS INITIAL.
    TRY.
        cl_salv_table=>factory(
          IMPORTING
            r_salv_table = go_alv
          CHANGING
            t_table      = lt_return ).

      CATCH cx_salv_msg.
    ENDTRY.

    IF go_alv IS BOUND.
      go_alv->set_screen_popup(
        start_column = '30'
        end_column   = '160'
        start_line   = '2'
        end_line     = '20' ).
      go_alv->display( ).

    ENDIF.
  ENDIF.