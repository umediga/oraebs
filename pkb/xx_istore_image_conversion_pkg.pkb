DROP PACKAGE BODY APPS.XX_ISTORE_IMAGE_CONVERSION_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_ISTORE_IMAGE_CONVERSION_PKG" AS

   /*------------------------------------------------------------------------------
   Procedure Name   :   main
   Parameters       :   x_errbuf                  OUT VARCHAR2
                        x_retcode                 OUT VARCHAR2
                        p_batch_id                IN  VARCHAR2
                        p_restart_flag            IN  VARCHAR2
                        p_validate_and_load       IN  VARCHAR2
   Purpose          :   This is the main procedure which subsequently calls
                        all other procedure.
   ------------------------------------------------------------------------------*/
   PROCEDURE main(x_errbuf             OUT VARCHAR2
                 ,x_retcode            OUT VARCHAR2
                 ,p_batch_id           IN  VARCHAR2
                 ,p_restart_flag       IN  VARCHAR2
                 ,p_validate_and_load  IN  VARCHAR2
                 )
   IS
      x_error_code          NUMBER          := xx_emf_cn_pkg.CN_SUCCESS;
      x_error_code_temp     NUMBER          := xx_emf_cn_pkg.CN_SUCCESS;
      x_sqlerrm             VARCHAR2(2000);
      x_istore_img_stg_table   g_xxistore_img_stg_tab_type;

      CURSOR c_xx_istore_img_stg ( cp_process_status VARCHAR2)
      IS
         SELECT *
           FROM xx_istore_img_stg
          WHERE batch_id     = G_BATCH_ID
            AND request_id   = G_REQUEST_ID
            AND process_code = cp_process_status
            AND error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN)
          ORDER BY record_number;


   PROCEDURE set_cnv_env (p_batch_id      VARCHAR2
                               ,p_required_flag VARCHAR2 DEFAULT xx_emf_cn_pkg.CN_YES
                               )
   IS
      x_error_code NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
   BEGIN
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside set_cnv_env...');
      G_BATCH_ID       := p_batch_id;
      xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'G_BATCH_ID: '||G_BATCH_ID );

      -- Set the environment
      x_error_code := xx_emf_pkg.set_env;
      IF NVL (p_required_flag, xx_emf_cn_pkg.CN_YES) <> xx_emf_cn_pkg.CN_NO THEN
         xx_emf_pkg.propagate_error(x_error_code);
      END IF;
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'End of mark.');
   EXCEPTION
      WHEN OTHERS THEN
         RAISE xx_emf_pkg.G_E_ENV_NOT_SET;
   END set_cnv_env;
             ----------------------------------------------------------------------------
   -------------------------------< dbg_low >----------------------------------
   ----------------------------------------------------------------------------
   PROCEDURE dbg_low (p_dbg_text VARCHAR2)
   IS
   BEGIN
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low
                            ,g_api_name
                            || ': '||
                            p_dbg_text
                           );
   END dbg_low;

   ----------------------------------------------------------------------------
   -------------------------------< dbg_med >----------------------------------
   ----------------------------------------------------------------------------
   PROCEDURE dbg_med (p_dbg_text VARCHAR2)
   IS
   BEGIN
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_medium
                            ,g_api_name
                            || ' : '||
                            p_dbg_text
                           );
   END dbg_med;

   ----------------------------------------------------------------------------
   -------------------------------< dbg_high >---------------------------------
   ----------------------------------------------------------------------------
   PROCEDURE dbg_high (p_dbg_text VARCHAR2)
   IS
   BEGIN
      xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_high
                            ,g_api_name
                            || ' : '||
                            p_dbg_text
                           );
   END dbg_high;
      ----------------------------------------------------------------------------
      --------------------------< update_record_status >--------------------------
      ----------------------------------------------------------------------------
      PROCEDURE update_record_status (p_conv_hdr_rec  IN OUT  g_xxistore_img_stg_rec_type,
                                      p_error_code    IN      VARCHAR2
                                     )
      IS
      BEGIN
         g_api_name := 'main.update_record_status';
         dbg_low('Inside update_record_status...');
         xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Inside of update record status...');
         IF p_error_code IN (xx_emf_cn_pkg.CN_REC_ERR, xx_emf_cn_pkg.CN_PRC_ERR)
         THEN
            p_conv_hdr_rec.error_code := xx_emf_cn_pkg.CN_REC_ERR;
         ELSE
            p_conv_hdr_rec.error_code := xx_intg_common_pkg.find_max(p_error_code,
                                         NVL (p_conv_hdr_rec.error_code, xx_emf_cn_pkg.CN_SUCCESS));
         END IF;
         p_conv_hdr_rec.process_code := G_STAGE;
         dbg_low('End of update record status.');
      END update_record_status;

      ----------------------------------------------------------------------------
      ---------------------------< update_stg_records >---------------------------
      ----------------------------------------------------------------------------
      PROCEDURE update_stg_records (p_xxistore_img_stg_table IN g_xxistore_img_stg_tab_type)
      IS
         x_last_update_date         DATE   := SYSDATE;
         x_last_updated_by          NUMBER := fnd_global.user_id;
         x_last_update_login        NUMBER := fnd_profile.value (xx_emf_cn_pkg.CN_LOGIN_ID);
         x_program_application_id   NUMBER := fnd_global.prog_appl_id;
         x_program_id               NUMBER := fnd_global.conc_program_id;
         x_program_update_date      DATE   := SYSDATE;
         indx                       NUMBER;
         PRAGMA AUTONOMOUS_TRANSACTION;
      BEGIN
         g_api_name := 'main.update_stg_records';
         dbg_low('Inside update_stg_records...');
         FOR indx IN 1 .. p_xxistore_img_stg_table.COUNT LOOP
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'p_xxistore_img_stg_table(indx).process_code ' || p_xxistore_img_stg_table(indx).process_code);
            xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'p_xxistore_img_stg_table(indx).error_code ' || p_xxistore_img_stg_table(indx).error_code);

            UPDATE xx_istore_img_stg
               SET segment1                     = NVL(p_xxistore_img_stg_table(indx).segment1,segment1)
                  ,inventory_item_id            = p_xxistore_img_stg_table(indx).inventory_item_id
                  ,site_code                    = p_xxistore_img_stg_table(indx).site_code
                  ,site_id                      = NVL(p_xxistore_img_stg_table(indx).site_id,site_id)
                  --,lang_code                    = NVL(p_xxistore_img_stg_table(indx).lang_code,lang_code)
                  ,process_code                 = p_xxistore_img_stg_table(indx).process_code
                  ,error_code                   = p_xxistore_img_stg_table(indx).error_code
                  ,created_by                   = p_xxistore_img_stg_table(indx).created_by
                  ,creation_date                = p_xxistore_img_stg_table(indx).creation_date
                  ,last_update_date             = x_last_update_date
                  ,last_updated_by              = x_last_updated_by
                  ,last_update_login            = x_last_update_login
                  ,request_id                   = p_xxistore_img_stg_table(indx).request_id
                  ,program_application_id       = x_program_application_id
                  ,program_id                   = x_program_id
                  ,program_update_date          = x_program_update_date
             WHERE record_number = p_xxistore_img_stg_table(indx).record_number
               AND batch_id      = p_xxistore_img_stg_table(indx).batch_id;
         END LOOP;
         COMMIT;
         dbg_low('End of update stg records.');
      END update_stg_records;

      -------------------------------------------------------------------------
      --------------------------< process_data >-------------------------------
      -------------------------------------------------------------------------
FUNCTION process_data
      RETURN NUMBER
      IS
         x_return_status VARCHAR2(15) := xx_emf_cn_pkg.CN_SUCCESS;

         CURSOR xx_istore_img_stg_cur
         IS
         SELECT *
           FROM xx_istore_img_stg
          WHERE 1 = 1
           -- AND error_code IN (xx_emf_cn_pkg.CN_SUCCESS,xx_emf_cn_pkg.CN_REC_WARN)
            AND process_code = xx_emf_cn_pkg.CN_POSTVAL
            AND batch_id     = G_BATCH_ID
          ORDER BY record_number;


      lv_return_status                  VARCHAR2(1);
      ln_msg_count                      NUMBER;
      lv_msg_data                       VARCHAR2(4000);


      x_message_data                   VARCHAR2(2000);
      x_error_buf                      VARCHAR2(4000);
      x_msg_index_out                  NUMBER;

      x_deliverable_id                 NUMBER;
      x_image_item_id                  NUMBER;
      x_image_name                     VARCHAR2(100);
      x_sqlerrm                         VARCHAR2(2000);

      x_media_exists                   NUMBER;

      skip_rec_exception                EXCEPTION;


      xx_deliverable_rec IBE_Deliverable_GRP.DELIVERABLE_REC_TYPE;

      xx_lang_tab IBE_PHYSICALMAP_GRP.LANGUAGE_CODE_TBL_TYPE := IBE_PHYSICALMAP_GRP.LANGUAGE_CODE_TBL_TYPE(NULL);

      xx_msite_lang_tab      IBE_PHYSICALMAP_GRP.msite_lang_tbl_type;

      xx_lgl_ctnt_tbl  IBE_LogicalContent_Grp.obj_lgl_ctnt_tbl_type;

      -- For API4 (Oracle Bug)
      x_content_item_id_tbl  JTF_NUMBER_TABLE := JTF_NUMBER_TABLE(0);
      x_version_number_tbl   JTF_NUMBER_TABLE := JTF_NUMBER_TABLE(1);
      x_no_version_exists    NUMBER := 0;

      BEGIN

         FOR xx_istore_img_stg_rec IN xx_istore_img_stg_cur
         LOOP

           SAVEPOINT CREATE_CURR_REC;
            BEGIN

               dbg_low('Inside API1...');
               ln_msg_count := 0;
               lv_msg_data := NULL;
               x_error_buf := NULL;
               x_message_data := NULL;
               x_sqlerrm := NULL;
               x_deliverable_id := NULL;
               x_image_name := NULL;
               x_image_item_id := NULL;
               x_media_exists := NULL;

               fnd_msg_pub.delete_msg;

               BEGIN


                  IF length(xx_istore_img_stg_rec.image_file_name) <= 40 THEN

                       SELECT item_id
                         INTO x_deliverable_id
                         FROM jtf_amv_items_b
                        WHERE access_name = xx_istore_img_stg_rec.image_file_name;

                  ELSE

                      SELECT item_id
                         INTO x_deliverable_id
                         FROM jtf_amv_items_b
                        WHERE access_name = SUBSTR(xx_istore_img_stg_rec.image_file_name, length(xx_istore_img_stg_rec.image_file_name) -39,
                                                            length(xx_istore_img_stg_rec.image_file_name));
                   END IF;

                  EXCEPTION

                       WHEN NO_DATA_FOUND THEN
                         x_deliverable_id := NULL;


                       WHEN OTHERS THEN
                          dbg_low('Error while checking Media Object exists');
                          x_sqlerrm := sqlerrm;
                          x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                          xx_emf_pkg.error (p_severity             => xx_emf_cn_pkg.CN_HIGH
                                            ,p_category            => xx_emf_cn_pkg.CN_TECH_ERROR
                                            ,p_error_text          => x_sqlerrm
                                            ,p_record_identifier_4 => 'While checking Media Object exists'
                                           );
                        RETURN x_error_code;
                        --RAISE skip_rec_exception;
                     END;

               IF x_deliverable_id IS NOT NULL THEN

                 UPDATE xx_istore_img_stg
                         SET deliverable_id     = x_deliverable_id
                            ,process_code       = xx_emf_cn_pkg.CN_PROCESS_DATA
                       WHERE batch_id           = G_BATCH_ID
                         AND record_number      = xx_istore_img_stg_rec.record_number;

                 x_media_exists := 1;

              ELSE

              x_media_exists := 0;

                   BEGIN

                       SELECT substr(xx_istore_img_stg_rec.image_file_name, instr(xx_istore_img_stg_rec.image_file_name,'/', -1)+ 1 )
                         INTO x_image_name
                         FROM dual;

                       SELECT citem_id
                         INTO x_image_item_id
                         FROM ibc_citems_v
                        WHERE --upper(directory_path||name) = upper(xx_istore_img_stg_rec.image_file_name)
                              upper(name) = upper(x_image_name)
                          AND upper(directory_path) = upper(replace(xx_istore_img_stg_rec.image_file_name,'/'||x_image_name,''))
                          AND language = G_LANGUAGE;

                   --Will not work for images in Root

                       /*SELECT citem_id,name  --Will not work for images in Root
                         INTO x_image_item_id, x_image_name
                         FROM ibc_citems_v
                        WHERE upper(directory_path||'/'||name) = upper(xx_istore_img_stg_rec.image_file_name)
                          AND language = G_LANGUAGE;*/


                           EXCEPTION

                           WHEN NO_DATA_FOUND THEN
                              dbg_low('No Image found..');
                              x_sqlerrm := sqlerrm;
                              x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                              xx_emf_pkg.error (p_severity             => xx_emf_cn_pkg.CN_HIGH
                                                ,p_category            => xx_emf_cn_pkg.CN_TECH_ERROR
                                                ,p_error_text          => x_sqlerrm
                                                ,p_record_identifier_4 => 'No Data Found while Fetching Image Content ID'
                                               );
                            RETURN x_error_code;

                           WHEN OTHERS THEN
                              dbg_low('Error while fetching Image ID');
                              x_sqlerrm := sqlerrm;
                              x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                              xx_emf_pkg.error (p_severity             => xx_emf_cn_pkg.CN_HIGH
                                                ,p_category            => xx_emf_cn_pkg.CN_TECH_ERROR
                                                ,p_error_text          => x_sqlerrm
                                                ,p_record_identifier_4 => 'While Fetching Image Content ID'
                                               );
                            RETURN x_error_code;
                            --RAISE skip_rec_exception;
                         END;


                      xx_deliverable_rec.deliverable_id := NULL;  --'Create flow'
                      IF length(xx_istore_img_stg_rec.image_file_name) <= 40 THEN
                        xx_deliverable_rec.access_name := xx_istore_img_stg_rec.image_file_name;
                      ELSE
                      xx_deliverable_rec.access_name := substr(xx_istore_img_stg_rec.image_file_name, length(xx_istore_img_stg_rec.image_file_name) -39,
                                                            length(xx_istore_img_stg_rec.image_file_name)); --Changed to fetch last 40 Chars as API accepts 40
                      END IF;
                      xx_deliverable_rec.display_name := xx_istore_img_stg_rec.image_file_name; --gv_display_name;
                      xx_deliverable_rec.item_type := 'MEDIA';
                      xx_deliverable_rec.item_applicable_to := gv_item_applicable_to;
                      xx_deliverable_rec.keywords := NULL;
                      xx_deliverable_rec.description := NULL;
                      xx_deliverable_rec.object_version_number := NULL;
                      xx_deliverable_rec.x_action_status := NULL;

                   IBE_Deliverable_GRP.save_deliverable(
                          p_api_version         => g_api_version,
                          p_init_msg_list       => FND_API.g_false,
                          p_commit              => FND_API.g_false,
                          x_return_status       => lv_return_status,
                          x_msg_count           => ln_msg_count,
                          x_msg_data            => lv_msg_data,
                          p_deliverable_rec     => xx_deliverable_rec );



                   IF lv_return_status <> 'S' THEN
                           FOR cur_err_rec IN 1 .. ln_msg_count
                           LOOP
                              fnd_msg_pub.get (p_msg_index          => cur_err_rec,
                                               p_encoded            => fnd_api.g_false,
                                               p_data               => x_message_data,
                                               p_msg_index_out      => x_msg_index_out
                                              );
                              x_error_buf := x_error_buf||x_message_data;
                           END LOOP;

                           x_sqlerrm := substr(x_error_buf,1,800);
                           x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                           xx_emf_pkg.error (p_severity            =>   xx_emf_cn_pkg.CN_MEDIUM
                                            ,p_category            =>   xx_emf_cn_pkg.CN_TECH_ERROR
                                            ,p_error_text          =>   x_sqlerrm
                                            ,p_record_identifier_1 =>   xx_istore_img_stg_rec.segment1
                                            ,p_record_identifier_2 =>   xx_istore_img_stg_rec.image_file_name
                                            ,p_record_identifier_3 =>   xx_istore_img_stg_rec.site_id
                                            --,p_record_identifier_4 =>   xx_istore_img_stg_rec.lang_code
                                            );

                           RAISE skip_rec_exception;

                   ELSE
                      UPDATE xx_istore_img_stg
                         SET deliverable_id     = xx_deliverable_rec.deliverable_id
                            ,process_code       = xx_emf_cn_pkg.CN_PROCESS_DATA
                       WHERE batch_id           = G_BATCH_ID
                         AND record_number      = xx_istore_img_stg_rec.record_number;

                       x_deliverable_id :=  xx_deliverable_rec.deliverable_id;

                        dbg_low('Success ! API1 returned deliverable_id...'||x_deliverable_id);

                   END IF;


                   -- If Media Object is created , link it with Image:


                   BEGIN

                   ln_msg_count := 0;
                   lv_msg_data := NULL;
                   x_error_buf := NULL;
                   x_message_data := NULL;


                   fnd_msg_pub.delete_msg;


                   dbg_low('Inside API2');

                        xx_lang_tab(1) := NULL;

                   IF (xx_istore_img_stg_rec.site_id) IS NOT NULL THEN
                        xx_msite_lang_tab(1).msite_id := xx_istore_img_stg_rec.site_id;
                        xx_msite_lang_tab(1).lang_count := 1;
                   ELSE
                       xx_msite_lang_tab(1).msite_id := NULL;
                        xx_msite_lang_tab(1).lang_count := 1;
                   END IF;

                   dbg_low('Calling API for deliverable_id...'||x_deliverable_id);
                   dbg_low('and Image ID...'||x_image_item_id);
                   dbg_low('and Site ID...'||xx_msite_lang_tab(1).msite_id);
                   dbg_low('and lang code...'||xx_lang_tab(1));


                   IBE_PHYSICALMAP_GRP.SAVE_PHYSICALMAP(
                        p_api_version      => g_api_version,
                        p_init_msg_list    => FND_API.g_false,
                        p_commit           => FND_API.g_false,
                        x_return_status    => lv_return_status,
                        x_msg_count        => ln_msg_count,
                        x_msg_data         => lv_msg_data,
                        p_deliverable_id   => x_deliverable_id,
                        p_old_content_key  => '',
                        p_new_content_key  => x_image_item_id,  -- image attachment_id
                        p_msite_lang_tbl   => xx_msite_lang_tab,
                        p_language_code_tbl => xx_lang_tab);


                        IF lv_return_status <> 'S' THEN
                               FOR cur_err_rec IN 1 .. ln_msg_count
                               LOOP
                                  fnd_msg_pub.get (p_msg_index          => cur_err_rec,
                                                   p_encoded            => fnd_api.g_false,
                                                   p_data               => x_message_data,
                                                   p_msg_index_out      => x_msg_index_out
                                                  );
                                  x_error_buf := x_error_buf||x_message_data;
                               END LOOP;

                               x_sqlerrm := substr(x_error_buf,1,800);
                               x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                               xx_emf_pkg.error (p_severity            =>   xx_emf_cn_pkg.CN_MEDIUM
                                                ,p_category            =>   xx_emf_cn_pkg.CN_TECH_ERROR
                                                ,p_error_text          =>   x_sqlerrm
                                                ,p_record_identifier_1 =>   xx_istore_img_stg_rec.segment1
                                                ,p_record_identifier_2 =>   xx_istore_img_stg_rec.image_file_name
                                                ,p_record_identifier_3 =>   xx_istore_img_stg_rec.site_id
                                                --,p_record_identifier_4 =>   xx_istore_img_stg_rec.lang_code
                                                );

                                dbg_low('x_sqlerrm..'||x_sqlerrm);

                               RAISE skip_rec_exception;

                        ELSE
                          UPDATE xx_istore_img_stg
                             SET --deliverable_id     = xx_deliverable_rec.deliverable_id
                                 process_code       = xx_emf_cn_pkg.CN_PROCESS_DATA
                           WHERE batch_id           = G_BATCH_ID
                             AND record_number      = xx_istore_img_stg_rec.record_number;

                           dbg_low('Success !..API2.');

                        END IF;

                         xx_msite_lang_tab.DELETE;
                         xx_lang_tab(1) := NULL;

                   EXCEPTION
                       WHEN OTHERS THEN
                          x_sqlerrm := sqlerrm;
                          x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                          xx_emf_pkg.error (p_severity             => xx_emf_cn_pkg.CN_HIGH
                                            ,p_category            => xx_emf_cn_pkg.CN_TECH_ERROR
                                            ,p_error_text          => x_sqlerrm
                                            ,p_record_identifier_4 => 'While (Img-Media Obj) IBE_PHYSICALMAP_GRP.SAVE_PHYSICALMAP'
                                           );
                        RETURN x_error_code;
                        --RAISE skip_rec_exception;
                   END;

              END IF;

               -- Once Image is linked with media Object, attach with product:
               BEGIN

                    dbg_low('Inside API3');
                    ln_msg_count := 0;
                    lv_msg_data := NULL;
                    x_error_buf := NULL;
                    x_message_data := NULL;

                    xx_lgl_ctnt_tbl.DELETE;
                    fnd_msg_pub.delete_msg;

                    xx_lgl_ctnt_tbl(1).obj_lgl_ctnt_delete := FND_API.g_false;
                    xx_lgl_ctnt_tbl(1).Object_Version_Number := NULL;
                    xx_lgl_ctnt_tbl(1).OBJ_lgl_ctnt_id := NULL;
                    xx_lgl_ctnt_tbl(1).context_id := gv_context_id;
                    xx_lgl_ctnt_tbl(1).Object_id := xx_istore_img_stg_rec.inventory_item_id; --inv_item_id
                    xx_lgl_ctnt_tbl(1).deliverable_id := x_deliverable_id;

                    dbg_low('---------------------------------------------------');
                    dbg_low('Calling API for context_id...'||gv_context_id);
                    dbg_low('and for inventory_item_id...'||xx_istore_img_stg_rec.inventory_item_id);
                    dbg_low('and for deliverable_id...'||x_deliverable_id);

                    IBE_LogicalContent_Grp.save_delete_lgl_ctnt(
                          p_api_version       => g_api_version,
                          p_init_msg_list       => FND_API.g_false,
                          p_commit              => FND_API.g_false,
                          x_return_status       => lv_return_status,
                          x_msg_count           => ln_msg_count,
                          x_msg_data            => lv_msg_data,
                          p_object_type_code    => gv_object_type_code,
                          p_lgl_ctnt_tbl        => xx_lgl_ctnt_tbl);

                   IF lv_return_status <> 'S' THEN
                           FOR cur_err_rec IN 1 .. ln_msg_count
                           LOOP
                              fnd_msg_pub.get (p_msg_index          => cur_err_rec,
                                               p_encoded            => fnd_api.g_false,
                                               p_data               => x_message_data,
                                               p_msg_index_out      => x_msg_index_out
                                              );
                              x_error_buf := x_error_buf||x_message_data;
                           END LOOP;

                           x_sqlerrm := substr(x_error_buf,1,800);
                           x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                           dbg_low('x_sqlerrm...'||x_sqlerrm);
                           xx_emf_pkg.error (p_severity            =>   xx_emf_cn_pkg.CN_MEDIUM
                                            ,p_category            =>   xx_emf_cn_pkg.CN_TECH_ERROR
                                            ,p_error_text          =>   x_sqlerrm
                                            ,p_record_identifier_1 =>   xx_istore_img_stg_rec.segment1
                                            ,p_record_identifier_2 =>   xx_istore_img_stg_rec.image_file_name
                                            ,p_record_identifier_3 =>   xx_istore_img_stg_rec.site_id
                                            --,p_record_identifier_4 =>   xx_istore_img_stg_rec.lang_code
                                            );


                           RAISE skip_rec_exception;

                   ELSE
                      UPDATE xx_istore_img_stg
                         SET --deliverable_id     = xx_deliverable_rec.deliverable_id
                            process_code       = xx_emf_cn_pkg.CN_PROCESS_DATA
                       WHERE batch_id           = G_BATCH_ID
                         AND record_number      = xx_istore_img_stg_rec.record_number;

                     dbg_low('API3 Success!!');

                   END IF;

               EXCEPTION
                   WHEN OTHERS THEN
                      x_sqlerrm := sqlerrm;
                      x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                      xx_emf_pkg.error (p_severity             => xx_emf_cn_pkg.CN_HIGH
                                        ,p_category            => xx_emf_cn_pkg.CN_TECH_ERROR
                                        ,p_error_text          => x_sqlerrm
                                        ,p_record_identifier_4 => 'While (Product-Media Obj) IBE_LogicalContent_Grp.save_delete_lgl_ctnt'
                                       );
                    RETURN x_error_code;
                    --RAISE skip_rec_exception;
               END;


               /****************** Added to correct Oracle Bug (SR 3-5821746821) ***************/

               -- Will insert data into IBC_CITEM_VERSION_LABELS:   (code kept for future Reference)

               --x_no_version_exists := 0;

               /*BEGIN

               SELECT 1 INTO x_no_version_exists FROM DUAL
                 WHERE NOT EXISTS (SELECT content_item_id
                                 FROM IBC_CITEM_VERSION_LABELS
                                WHERE content_item_id = x_image_item_id );
               EXCEPTION

                       WHEN NO_DATA_FOUND THEN
                          dbg_low('Label Exists..No Need to call API4');


                       WHEN OTHERS THEN
                          dbg_low('Error while fetching Version Details');
                          x_sqlerrm := sqlerrm;
                          x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                          xx_emf_pkg.error (p_severity             => xx_emf_cn_pkg.CN_HIGH
                                            ,p_category            => xx_emf_cn_pkg.CN_TECH_ERROR
                                            ,p_error_text          => x_sqlerrm
                                            ,p_record_identifier_4 => 'While Fetching Version Details'
                                           );
                        RETURN x_error_code;
                        --RAISE skip_rec_exception;
               END;*/

               --IF x_no_version_exists = 1 THEN
               IF x_media_exists = 0 THEN
                   BEGIN

                        dbg_low('Inside API4');
                        ln_msg_count := 0;
                        lv_msg_data := NULL;
                        x_error_buf := NULL;
                        x_message_data := NULL;

                        --xx_lgl_ctnt_tbl.DELETE;
                        fnd_msg_pub.delete_msg;

                        x_content_item_id_tbl(1) := x_image_item_id;
                        x_version_number_tbl(1) := 1;

                        dbg_low('---------------------------------------------------');
                        dbg_low('Calling API for content...'||x_image_item_id);

                        IBE_M_IBC_INT_PVT.Batch_Update_Labels(
                              p_api_version         => g_api_version,
                              p_init_msg_list       => FND_API.g_true,
                              p_commit              => FND_API.g_true,
                              p_content_item_id_tbl => x_content_item_id_tbl,
                              p_version_number_tbl  => x_version_number_tbl,
                              x_return_status       => lv_return_status,
                              x_msg_count           => ln_msg_count,
                              x_msg_data            => lv_msg_data);

                       IF lv_return_status <> 'S' THEN
                               FOR cur_err_rec IN 1 .. ln_msg_count
                               LOOP
                                  fnd_msg_pub.get (p_msg_index          => cur_err_rec,
                                                   p_encoded            => fnd_api.g_false,
                                                   p_data               => x_message_data,
                                                   p_msg_index_out      => x_msg_index_out
                                                  );
                                  x_error_buf := x_error_buf||x_message_data;
                               END LOOP;

                               x_sqlerrm := substr(x_error_buf,1,800);
                               x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                               dbg_low('x_sqlerrm...'||x_sqlerrm);
                               xx_emf_pkg.error (p_severity            =>   xx_emf_cn_pkg.CN_MEDIUM
                                                ,p_category            =>   xx_emf_cn_pkg.CN_TECH_ERROR
                                                ,p_error_text          =>   x_sqlerrm
                                                ,p_record_identifier_1 =>   xx_istore_img_stg_rec.segment1
                                                ,p_record_identifier_2 =>   xx_istore_img_stg_rec.image_file_name
                                                ,p_record_identifier_3 =>   xx_istore_img_stg_rec.site_id
                                                --,p_record_identifier_4 =>   xx_istore_img_stg_rec.lang_code
                                                );


                               RAISE skip_rec_exception;

                       ELSE
                          UPDATE xx_istore_img_stg
                             SET --deliverable_id     = xx_deliverable_rec.deliverable_id
                                process_code       = xx_emf_cn_pkg.CN_PROCESS_DATA
                           WHERE batch_id           = G_BATCH_ID
                             AND record_number      = xx_istore_img_stg_rec.record_number;

                         dbg_low('API4 Success!!');

                       END IF;

                   EXCEPTION
                       WHEN OTHERS THEN
                          x_sqlerrm := sqlerrm;
                          x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                          xx_emf_pkg.error (p_severity             => xx_emf_cn_pkg.CN_HIGH
                                            ,p_category            => xx_emf_cn_pkg.CN_TECH_ERROR
                                            ,p_error_text          => x_sqlerrm
                                            ,p_record_identifier_4 => 'While IBE_M_IBC_INT_PVT.Batch_Update_Labels was run'
                                           );
                        RETURN x_error_code;
                        --RAISE skip_rec_exception;
                   END;
                --END IF;
                END IF;

               /***** End of Addition *************/







               COMMIT;


            EXCEPTION
                WHEN skip_rec_exception THEN
                          --Skip Record and move to next
                          dbg_low('In Skip rec Exception');
                          dbg_low('Rolling Back the API 1,2,3,4 process for current record');

                          ROLLBACK TO CREATE_CURR_REC;

                           x_sqlerrm := substr(x_error_buf,1,800);
                           x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                           xx_emf_pkg.error (p_severity            =>   xx_emf_cn_pkg.CN_MEDIUM
                                            ,p_category            =>   xx_emf_cn_pkg.CN_TECH_ERROR
                                            ,p_error_text          =>   x_sqlerrm
                                            ,p_record_identifier_1 =>   xx_istore_img_stg_rec.segment1
                                            ,p_record_identifier_2 =>   xx_istore_img_stg_rec.image_file_name
                                            ,p_record_identifier_3 =>   xx_istore_img_stg_rec.site_id
                                            --,p_record_identifier_4 =>   xx_istore_img_stg_rec.lang_code
                                            );
                           UPDATE xx_istore_img_stg
                              SET error_code         = x_error_code
                                 ,error_desc         = x_sqlerrm
                                 ,process_code       = xx_emf_cn_pkg.CN_PROCESS_DATA
                            WHERE batch_id           = G_BATCH_ID
                              AND record_number      = xx_istore_img_stg_rec.record_number;
                WHEN OTHERS THEN
                    dbg_low('Rolling Back the API 1,2,3 process for current record');
                    ROLLBACK TO CREATE_CURR_REC;
                    dbg_low('In When Others of loop proc');
                      x_sqlerrm := substr(sqlerrm,1,800);
                      x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
                    xx_emf_pkg.error (p_severity            =>   xx_emf_cn_pkg.CN_MEDIUM
                                   ,p_category            =>   xx_emf_cn_pkg.CN_TECH_ERROR
                                   ,p_error_text          =>   x_sqlerrm
                                   ,p_record_identifier_1 =>   xx_istore_img_stg_rec.segment1
                                   ,p_record_identifier_2 =>   xx_istore_img_stg_rec.image_file_name
                                   ,p_record_identifier_3 =>   xx_istore_img_stg_rec.site_id
                                   --,p_record_identifier_4 =>   xx_istore_img_stg_rec.lang_code
                                   );
                  UPDATE xx_istore_img_stg
                     SET error_code         = x_error_code
                        , error_desc        = x_sqlerrm
                        ,process_code       = xx_emf_cn_pkg.CN_PROCESS_DATA
                   WHERE batch_id           = G_BATCH_ID
                     AND record_number      = xx_istore_img_stg_rec.record_number;
                   --COMMIT;
            END;
            --COMMIT;
         END LOOP;
         RETURN x_return_status;


      EXCEPTION
            WHEN OTHERS THEN
            dbg_low('In When Others of proc');
              x_sqlerrm := sqlerrm;
              x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
              xx_emf_pkg.error (p_severity             => xx_emf_cn_pkg.CN_HIGH
                                ,p_category            => xx_emf_cn_pkg.CN_TECH_ERROR
                                ,p_error_text          => x_sqlerrm
                                ,p_record_identifier_4 => 'Process to Create Media Object and link with Image/Product'
                               );
              RETURN x_error_code;
      END process_data;

      -- mark_records_complete
      PROCEDURE mark_records_complete (p_process_code           VARCHAR2)
      IS
         x_last_update_date       DATE   := SYSDATE;
         x_last_updated_by        NUMBER := fnd_global.user_id;
         x_last_update_login      NUMBER := fnd_profile.value (xx_emf_cn_pkg.CN_LOGIN_ID);
         PRAGMA AUTONOMOUS_TRANSACTION;
      BEGIN
         g_api_name := 'main.mark_records_complete';
         dbg_low('Inside mark_records_complete...');

         UPDATE xx_istore_img_stg
            SET process_code      = G_STAGE,
                error_code        = NVL (error_code, xx_emf_cn_pkg.CN_SUCCESS),
                last_updated_by   = x_last_updated_by,
                last_update_date  = x_last_update_date,
                last_update_login = x_last_update_login
          WHERE batch_id     = G_BATCH_ID
            AND request_id   = xx_emf_pkg.G_REQUEST_ID
            AND process_code = DECODE (p_process_code
                                      ,xx_emf_cn_pkg.CN_PROCESS_DATA
                                      ,xx_emf_cn_pkg.CN_POSTVAL
                                      ,xx_emf_cn_pkg.CN_DERIVE)
            AND error_code IN ( xx_emf_cn_pkg.CN_SUCCESS, xx_emf_cn_pkg.CN_REC_WARN);
         COMMIT;
         dbg_low('End of mark records complete.');
      EXCEPTION
      WHEN OTHERS THEN
         dbg_low('Error in Update of mark records complete: '||SQLERRM);
      END mark_records_complete;

         ----------------------------------------------------------------------------
   ---------------------< mark_records_for_processing >------------------------
   ----------------------------------------------------------------------------
   PROCEDURE mark_records_for_processing (p_restart_flag  IN VARCHAR2)
   IS
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      g_api_name := 'mark_records_for_processing';
      dbg_low('Inside of mark records for processing...');
      IF p_restart_flag = xx_emf_cn_pkg.CN_ALL_RECS THEN
         UPDATE xx_istore_img_stg
            SET request_id = xx_emf_pkg.G_REQUEST_ID,
                error_code = xx_emf_cn_pkg.CN_NULL,
                error_desc = xx_emf_cn_pkg.CN_NULL,
                process_code = xx_emf_cn_pkg.CN_NEW
          WHERE batch_id = G_BATCH_ID;
            --AND NVL(process_code,xx_emf_cn_pkg.CN_NEW) NOT IN(xx_emf_cn_pkg.CN_PROCESS_DATA);
      ELSIF p_restart_flag = xx_emf_cn_pkg.CN_ERR_RECS THEN
         UPDATE xx_istore_img_stg
            SET request_id   = xx_emf_pkg.G_REQUEST_ID,
                error_code   = xx_emf_cn_pkg.CN_NULL,
                error_desc = xx_emf_cn_pkg.CN_NULL,
                process_code = xx_emf_cn_pkg.CN_NEW
          WHERE batch_id = G_BATCH_ID
            AND NVL (error_code, xx_emf_cn_pkg.CN_REC_ERR) IN
                (xx_emf_cn_pkg.CN_REC_WARN, xx_emf_cn_pkg.CN_REC_ERR,xx_emf_cn_pkg.CN_PRC_ERR);
      END IF;
      COMMIT;
      dbg_low('End of mark records for processing.');
   END mark_records_for_processing;

      ----------------------------------------------------------------------------
   ------------------------------< set_stage >---------------------------------
   ----------------------------------------------------------------------------
    PROCEDURE set_stage (p_stage VARCHAR2)
    IS
    BEGIN
       G_STAGE := p_stage;
    END set_stage;

   ----------------------------------------------------------------------------
   ------------------------< update_staging_records >--------------------------
   ----------------------------------------------------------------------------
   PROCEDURE update_staging_records( p_error_code VARCHAR2)
   IS
      x_last_update_date     DATE   := SYSDATE;
      x_last_update_login    NUMBER := fnd_profile.value (xx_emf_cn_pkg.CN_LOGIN_ID);


      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      g_api_name := 'update_staging_records';
      dbg_low('Inside update_staging_records...');

      UPDATE xx_istore_img_stg
         SET process_code = G_STAGE,
             error_code = DECODE ( error_code, NULL, p_error_code, error_code),
             last_update_date = x_last_update_date,
             last_updated_by   = G_USER_ID,
             last_update_login = x_last_update_login -- In template please make change
       WHERE batch_id = G_BATCH_ID
         AND request_id = xx_emf_pkg.G_REQUEST_ID
         AND process_code = xx_emf_cn_pkg.CN_NEW;-- To dynamically change process at different stages (pre-val/data-deri)

      COMMIT;
      dbg_low('End of update staging records.');
   EXCEPTION
      WHEN OTHERS THEN
         dbg_low('Error while updating staging records status: '||SQLERRM);
   END update_staging_records;

      PROCEDURE update_record_count
   IS
      CURSOR c_get_total_cnt
      IS
         SELECT COUNT (1) total_count
           FROM xx_istore_img_stg
          WHERE batch_id = G_BATCH_ID
            AND request_id = xx_emf_pkg.G_REQUEST_ID;

      x_total_cnt NUMBER;

      CURSOR c_get_error_cnt
      IS
         SELECT SUM(error_count)
           FROM (
               SELECT COUNT (1) error_count
                 FROM xx_istore_img_stg
                WHERE batch_id   = G_BATCH_ID
                  AND request_id = xx_emf_pkg.G_REQUEST_ID
                  AND error_code = xx_emf_cn_pkg.CN_REC_ERR);

      x_error_cnt NUMBER;

      CURSOR c_get_warning_cnt
      IS
         SELECT COUNT (1) warn_count
           FROM xx_istore_img_stg
          WHERE batch_id = G_BATCH_ID
            AND request_id = xx_emf_pkg.G_REQUEST_ID
            AND error_code = xx_emf_cn_pkg.CN_REC_WARN;

      x_warn_cnt NUMBER;

      CURSOR c_get_success_cnt (c_validate NUMBER)
      IS
         SELECT COUNT (1) success_count
           FROM xx_istore_img_stg
          WHERE batch_id = G_BATCH_ID
            AND request_id = xx_emf_pkg.G_REQUEST_ID
            AND process_code = decode(c_validate,1,process_code,xx_emf_cn_pkg.CN_PROCESS_DATA)
            AND error_code = xx_emf_cn_pkg.CN_SUCCESS;

      x_success_cnt NUMBER;
      x_validate    NUMBER;

   BEGIN

      IF g_validate_flag = TRUE THEN
         x_validate := 1;
      ELSE
         x_validate := 0;
      END IF;

      OPEN c_get_total_cnt;
      FETCH c_get_total_cnt INTO x_total_cnt;
      CLOSE c_get_total_cnt;
      dbg_low('x_total_cnt:'||x_total_cnt);

      OPEN c_get_error_cnt;
      FETCH c_get_error_cnt INTO x_error_cnt;
      CLOSE c_get_error_cnt;
      dbg_low('x_error_cnt:'||x_error_cnt);

      OPEN c_get_warning_cnt;
      FETCH c_get_warning_cnt INTO x_warn_cnt;
      CLOSE c_get_warning_cnt;
      dbg_low('x_warn_cnt:'||x_warn_cnt);

      OPEN c_get_success_cnt(x_validate);
      FETCH c_get_success_cnt INTO x_success_cnt;
      CLOSE c_get_success_cnt;
      dbg_low('x_success_cnt:'||x_success_cnt);

      xx_emf_pkg.update_recs_cnt
      (p_total_recs_cnt   => x_total_cnt
      ,p_success_recs_cnt => x_success_cnt
      ,p_warning_recs_cnt => x_warn_cnt
      ,p_error_recs_cnt   => x_error_cnt
      );
   END update_record_count;

      ----------------------------------------------------------------------------
   -------------------------------< find_max >---------------------------------
   ----------------------------------------------------------------------------
   FUNCTION find_max (p_error_code1 IN VARCHAR2,
                      p_error_code2 IN VARCHAR2
                     )
   RETURN VARCHAR2
   IS
      x_return_value VARCHAR2(100);
   BEGIN
      x_return_value := xx_intg_common_pkg.find_max(p_error_code1, p_error_code2);
    RETURN x_return_value;
   END find_max;


      ----------------------------------------------------------------------------
   ----------------------------< pre_validations >-----------------------------
   ----------------------------------------------------------------------------
   FUNCTION pre_validations
   RETURN NUMBER
   IS
      x_error_code      NUMBER   := xx_emf_cn_pkg.CN_SUCCESS;
      x_error_code_temp NUMBER   := xx_emf_cn_pkg.CN_SUCCESS;
   BEGIN
      g_api_name := 'pre_validations';
      dbg_low('Inside pre_validations');
      dbg_low('End of pre validations.');
      RETURN x_error_code;
   EXCEPTION
      WHEN xx_emf_pkg.G_E_REC_ERROR THEN
         x_error_code := xx_emf_cn_pkg.cn_rec_err;
         RETURN x_error_code;
      WHEN xx_emf_pkg.G_E_PRC_ERROR THEN
         x_error_code := xx_emf_cn_pkg.cn_prc_err;
         RETURN x_error_code;
      WHEN OTHERS THEN
         x_error_code := xx_emf_cn_pkg.cn_prc_err;
         RETURN x_error_code;
   END pre_validations;

   ----------------------------------------------------------------------------
   ----------------------------< data_validations >----------------------------
   ----------------------------------------------------------------------------
   FUNCTION data_validations(csr_istore_image_stg_rec IN OUT xx_istore_image_conversion_pkg.g_xxistore_img_stg_rec_type)
   RETURN NUMBER
   IS
      x_error_code         NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
      x_error_code_temp    NUMBER := xx_emf_cn_pkg.CN_SUCCESS;



      ----------------------------------------------------------------------------
      ------------------------< inventory_item_is_valid>--------------------------
      ----------------------------------------------------------------------------
      FUNCTION inventory_item_is_valid(p_inventory_item  IN OUT   VARCHAR2)
      RETURN NUMBER
      IS
         x_error_code NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
        BEGIN

        dbg_low('g_master_org:'||g_master_org);

         SELECT msi.segment1
           INTO p_inventory_item
           FROM mtl_system_items_b msi,
                mtl_parameters mtp
          WHERE msi.organization_id = mtp.organization_id
            AND mtp.organization_code = g_master_org
            AND UPPER(msi.segment1) = UPPER(p_inventory_item) ;

        EXCEPTION
           WHEN too_many_rows THEN
           dbg_low('too -may-rws');
              x_error_code := xx_emf_cn_pkg.cn_rec_err;
              p_inventory_item := NULL;
              RETURN x_error_code;
           WHEN no_data_found THEN
           dbg_low('no-data-fnd');
              x_error_code := xx_emf_cn_pkg.cn_rec_err;
              p_inventory_item := NULL;
              RETURN x_error_code;
           WHEN others THEN
           dbg_low('wn othrs');
              x_error_code := xx_emf_cn_pkg.cn_rec_err;
              p_inventory_item := NULL;
              RETURN x_error_code;
        END;
        RETURN x_error_code;
      END inventory_item_is_valid;


            ----------------------------------------------------------------------------
      ------------------------< lang_code_is_valid>--------------------------
      ----------------------------------------------------------------------------
      FUNCTION lang_code_is_valid(p_lang_code  IN OUT   VARCHAR2)
      RETURN NUMBER
      IS
         x_error_code NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
          BEGIN

          dbg_low('p_lang_code:'||p_lang_code);

             SELECT language_code
               INTO p_lang_code
               FROM fnd_languages
              WHERE LTRIM(RTRIM(UPPER(language_code))) = LTRIM(RTRIM(UPPER(p_lang_code))) ;

          dbg_low('p_lang_code:'||p_lang_code);

            EXCEPTION
               WHEN too_many_rows THEN
               dbg_low('too many rows');
                  x_error_code := xx_emf_cn_pkg.cn_rec_err;
                  p_lang_code := NULL;
                  RETURN x_error_code;
               WHEN no_data_found THEN
               dbg_low('No Data Found');
                  x_error_code := xx_emf_cn_pkg.cn_rec_err;
                  p_lang_code := NULL;
                  RETURN x_error_code;
               WHEN others THEN
                  dbg_low('others');
                  x_error_code := xx_emf_cn_pkg.cn_rec_err;
                  p_lang_code := NULL;
                  RETURN x_error_code;
            END;
        RETURN x_error_code;
      END lang_code_is_valid;


      ----------------------------------------------------------------------------
      ------------------------< site_code_is_valid>--------------------------
      ----------------------------------------------------------------------------
      FUNCTION site_id_is_valid(p_site_id  IN OUT   VARCHAR2)
      RETURN NUMBER
      IS
         x_error_code NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
          BEGIN

             SELECT msite_id
               INTO p_site_id
               FROM ibe_msites_b
              WHERE msite_id = p_site_id ;

            EXCEPTION
               WHEN too_many_rows THEN
                  x_error_code := xx_emf_cn_pkg.cn_rec_err;
                  p_site_id := NULL;
                  RETURN x_error_code;
               WHEN no_data_found THEN
                  x_error_code := xx_emf_cn_pkg.cn_rec_err;
                  p_site_id := NULL;
                  RETURN x_error_code;
               WHEN others THEN
                  x_error_code := xx_emf_cn_pkg.cn_rec_err;
                  p_site_id := NULL;
                  RETURN x_error_code;
            END;
        RETURN x_error_code;
      END site_id_is_valid;

   BEGIN
      g_api_name := 'data_validations';
      dbg_low('Inside data_validations');

      IF csr_istore_image_stg_rec.image_file_name IS NULL THEN
        dbg_low('Image File Name is NULL');
        xx_emf_pkg.error(p_severity => xx_emf_cn_pkg.cn_low,
                             p_category => 'IMGFILE-VAL001',
                             p_error_text => 'E:'||'Image file Name is NULL',
                             p_record_identifier_1 =>   csr_istore_image_stg_rec.segment1
                            ,p_record_identifier_2 =>   csr_istore_image_stg_rec.image_file_name
                            ,p_record_identifier_3 =>   csr_istore_image_stg_rec.site_id
                            );
      END IF;

      IF csr_istore_image_stg_rec.segment1 IS NULL THEN
        dbg_low('Inventory Item is NULL');
        xx_emf_pkg.error(p_severity => xx_emf_cn_pkg.cn_low,
                             p_category => 'ITEMNULL-VAL001',
                             p_error_text => 'E:'||'Inventory Item is NULL',
                             p_record_identifier_1 =>   csr_istore_image_stg_rec.segment1
                            ,p_record_identifier_2 =>   csr_istore_image_stg_rec.image_file_name
                            ,p_record_identifier_3 =>   csr_istore_image_stg_rec.site_id
                            );
      END IF;

      IF csr_istore_image_stg_rec.segment1 IS NOT NULL THEN
         -- To validate Inventory_item
         x_error_code_temp := inventory_item_is_valid(csr_istore_image_stg_rec.segment1);
         x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp );
         IF csr_istore_image_stg_rec.segment1 IS NULL THEN
            dbg_low('Inventory Item is not Valid');
            xx_emf_pkg.error(p_severity => xx_emf_cn_pkg.cn_low,
                             p_category => 'ITEM-VAL001',
                             p_error_text => 'E:'||'Inventory Item is not valid',
                             p_record_identifier_1 =>   csr_istore_image_stg_rec.segment1
                            ,p_record_identifier_2 =>   csr_istore_image_stg_rec.image_file_name
                            ,p_record_identifier_3 =>   csr_istore_image_stg_rec.site_id
                            );
         END IF;
      END IF;


      IF csr_istore_image_stg_rec.site_id IS NOT NULL THEN
         -- To validate Language Code
         x_error_code_temp := site_id_is_valid(csr_istore_image_stg_rec.site_id);
         x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp );
         IF csr_istore_image_stg_rec.site_id IS NULL THEN
            dbg_low('Site ID is invalid');
            xx_emf_pkg.error(p_severity => xx_emf_cn_pkg.cn_low,
                             p_category => 'SITE-VAL003',
                             p_error_text => 'E:'||'Site ID is invalid',
                             p_record_identifier_1 =>   csr_istore_image_stg_rec.segment1
                            ,p_record_identifier_2 =>   csr_istore_image_stg_rec.image_file_name
                            ,p_record_identifier_3 =>   csr_istore_image_stg_rec.site_id
                            );
         END IF;
      END IF;
      dbg_low('End of data validations.');
      RETURN x_error_code;


   EXCEPTION
      WHEN xx_emf_pkg.G_E_REC_ERROR THEN
         x_error_code := xx_emf_cn_pkg.cn_rec_err;
         RETURN x_error_code;
      WHEN xx_emf_pkg.G_E_PRC_ERROR THEN
         x_error_code := xx_emf_cn_pkg.cn_prc_err;
         RETURN x_error_code;
      WHEN OTHERS THEN
         x_error_code := xx_emf_cn_pkg.cn_prc_err;
         RETURN x_error_code;
   END data_validations;

   ----------------------------------------------------------------------------
   ----------------------------< data_derivations >----------------------------
   ----------------------------------------------------------------------------
   FUNCTION data_derivations(csr_istore_image_stg_rec IN OUT xx_istore_image_conversion_pkg.g_xxistore_img_stg_rec_type)
   RETURN NUMBER
   IS
      x_error_code         NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
      x_error_code_temp    NUMBER := xx_emf_cn_pkg.CN_SUCCESS;

      ----------------------------------------------------------------------------
      --------------------------< get_invenory_item_id >----------------------------
      ----------------------------------------------------------------------------
      FUNCTION get_inventory_id(p_inventory_item    IN          VARCHAR2
                                 ,p_inventory_item_id      OUT NOCOPY  NUMBER
                                 )
      RETURN NUMBER
      IS
         x_error_code NUMBER := xx_emf_cn_pkg.cn_success;
      BEGIN
        p_inventory_item_id := NULL;
        BEGIN
           SELECT msi.inventory_item_id
             INTO p_inventory_item_id
             FROM mtl_system_items_b msi,
                  mtl_parameters mtp
            WHERE UPPER(msi.segment1) = UPPER(p_inventory_item)
              AND msi.organization_id = mtp.organization_id
              AND mtp.organization_code = g_master_org;
        EXCEPTION
           WHEN too_many_rows THEN
              x_error_code := xx_emf_cn_pkg.cn_rec_err;
              p_inventory_item_id := NULL;
              RETURN x_error_code;
           WHEN no_data_found THEN
              x_error_code := xx_emf_cn_pkg.cn_rec_err;
              p_inventory_item_id := NULL;
              RETURN x_error_code;
           WHEN others THEN
              x_error_code := xx_emf_cn_pkg.cn_rec_err;
              p_inventory_item_id := NULL;
              RETURN x_error_code;
        END;
        RETURN x_error_code;
      END get_inventory_id;

      ----------------------------------------------------------------------------
      -------------------------< get_site_id >--------------------------
      ----------------------------------------------------------------------------
      FUNCTION get_site_id(p_site_code       IN      VARCHAR2
                                    ,p_site_id    IN OUT    NUMBER
                                    )
      RETURN NUMBER
      IS
         x_error_code NUMBER := xx_emf_cn_pkg.cn_success;

      BEGIN
      p_site_id := NULL;
        BEGIN
           NULL;
        EXCEPTION
           WHEN too_many_rows THEN
              x_error_code := xx_emf_cn_pkg.cn_rec_err;
              p_site_id := NULL;
              RETURN x_error_code;
           WHEN no_data_found THEN
              x_error_code := xx_emf_cn_pkg.cn_rec_err;
              p_site_id := NULL;
              RETURN x_error_code;
           WHEN others THEN
              x_error_code := xx_emf_cn_pkg.cn_rec_err;
              p_site_id := NULL;
              RETURN x_error_code;
        END;
        RETURN x_error_code;
      END get_site_id;



   BEGIN
      g_api_name := 'data_derivations';
      dbg_low('Inside data_derivations');
      xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Inside Data-Derivations');


         x_error_code_temp := get_inventory_id(csr_istore_image_stg_rec.segment1
                                                ,csr_istore_image_stg_rec.inventory_item_id
                                                );
         x_error_code      := FIND_MAX ( x_error_code, x_error_code_temp );
         IF csr_istore_image_stg_rec.inventory_item_id IS NULL THEN
            dbg_low('inventory_item_id not derived');
            xx_emf_pkg.error(p_severity => xx_emf_cn_pkg.cn_low,
                             p_category => 'ITEM-DER001', --xx_emf_cn_pkg.cn_organization_valid, --check if its ok (custom code)
                             p_error_text => 'E:'||'inventory_item_id not derived',
                             p_record_identifier_1 =>   csr_istore_image_stg_rec.segment1
                            ,p_record_identifier_2 =>   csr_istore_image_stg_rec.image_file_name
                            ,p_record_identifier_3 =>   csr_istore_image_stg_rec.site_id
                            );
         END IF;

         dbg_low('End of data derivations.');
      RETURN x_error_code;
   EXCEPTION
   WHEN xx_emf_pkg.G_E_REC_ERROR THEN
      x_error_code := xx_emf_cn_pkg.CN_REC_ERR;
      RETURN x_error_code;
   WHEN xx_emf_pkg.G_E_PRC_ERROR THEN
      x_error_code := xx_emf_cn_pkg.CN_PRC_ERR;
      RETURN x_error_code;
   WHEN OTHERS THEN
      x_error_code := xx_emf_cn_pkg.CN_PRC_ERR;
      RETURN x_error_code;
   END data_derivations;

   --------------------------------------------------------------------------------
   ---------------------------< post_validations >---------------------------------
   --------------------------------------------------------------------------------
   FUNCTION post_validations
   RETURN NUMBER
   IS
      x_error_code         NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
      x_error_code_temp    NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
   BEGIN
      g_api_name := 'post_validations';
      dbg_low('Inside post_validations');
      dbg_low('End of post validations.');
      RETURN x_error_code;
   EXCEPTION
   WHEN xx_emf_pkg.g_e_rec_error THEN
      x_error_code := xx_emf_cn_pkg.cn_rec_err;
      RETURN x_error_code;
   WHEN xx_emf_pkg.g_e_prc_error THEN
      x_error_code := xx_emf_cn_pkg.cn_prc_err;
      RETURN x_error_code;
   WHEN others THEN
      x_error_code := xx_emf_cn_pkg.cn_prc_err;
      RETURN x_error_code;
   END post_validations;



   BEGIN
      --Main Begin
      g_api_name := 'Main';
      x_retcode := xx_emf_cn_pkg.CN_SUCCESS;
      dbg_low('Before Setting Environment');

      -- Set Env --
      dbg_low('Calling set_cnv_env..');
      set_cnv_env (p_batch_id,xx_emf_cn_pkg.CN_YES);

      -- Include all the parameters to the conversion main here
      -- as medium log messages
      dbg_med('Starting main process with the following parameters');
      dbg_med('Param - p_batch_id          '|| p_batch_id);
      dbg_med('Param - p_restart_flag      '|| p_restart_flag);
      dbg_med('Param - p_validate_and_load '|| p_validate_and_load);
      --Popluate the global variable for validate flag

      dbg_low('Initialising Constants..');
        xx_intg_common_pkg.get_process_param_value('XXISTOREIMGCNV','G_VALIDATE_AND_LOAD',G_VALIDATE_AND_LOAD);
        xx_intg_common_pkg.get_process_param_value('XXISTOREIMGCNV','GV_ITEM_APPLICABLE_TO',GV_ITEM_APPLICABLE_TO);
        xx_intg_common_pkg.get_process_param_value('XXISTOREIMGCNV','G_API_VERSION',G_API_VERSION);
        xx_intg_common_pkg.get_process_param_value('XXISTOREIMGCNV','GV_OBJECT_TYPE_CODE',GV_OBJECT_TYPE_CODE);
        xx_intg_common_pkg.get_process_param_value('XXISTOREIMGCNV','GV_CONTEXT_ID',GV_CONTEXT_ID);
        xx_intg_common_pkg.get_process_param_value('XXISTOREIMGCNV','G_MASTER_ORG',G_MASTER_ORG);
        xx_intg_common_pkg.get_process_param_value('XXISTOREIMGCNV','G_LANGUAGE',G_LANGUAGE);

       dbg_low('G_API_VERSION:'||G_API_VERSION);

      IF p_validate_and_load = g_validate_and_load THEN
         g_validate_flag := FALSE;
         --dbg_med('Param - g_validate_flag '|| g_validate_flag);
      ELSE
         g_validate_flag := TRUE;
         --dbg_med('Param - g_validate_flag '|| g_validate_flag);
      END IF;

      -- Call procedure to update records with the current request_id
      -- so that we can process only those records
      -- This gives a better handling of restarting
      dbg_low('Calling mark_records_for_processing..');
      mark_records_for_processing(p_restart_flag => p_restart_flag);

      -- Set the stage to Pre Validations
      /***************************************/
      set_stage (xx_emf_cn_pkg.CN_PREVAL);

      -- Change the validations package to the appropriate package name
      -- Modify the parameters as required
      -- DO NOT CHANGE ANYTHING ELSE IN THE CODE
      -- PRE_VALIDATIONS SHOULD BE RETAINED
      dbg_low('Calling pre_validations ..');
      x_error_code := pre_validations();
      dbg_med('After pre-validations X_ERROR_CODE : ' || X_ERROR_CODE);
      -- Update process code of staging records
      -- Update Header and Lines Level
      update_staging_records (x_error_code);
      xx_emf_pkg.propagate_error (x_error_code);

      dbg_low(G_REQUEST_ID || ' : Before Data Validations');
      -- Once pre-validations are complete loop through the pre-interface records
      -- and perform data validation on this table

      -- Set the stage to data Validations
      /***************************************/
      set_stage (xx_emf_cn_pkg.CN_VALID);

      OPEN c_xx_istore_img_stg ( xx_emf_cn_pkg.CN_PREVAL);
      LOOP
      FETCH c_xx_istore_img_stg
      BULK COLLECT INTO x_istore_img_stg_table LIMIT xx_emf_cn_pkg.CN_BULK_COLLECT;
         FOR i IN 1 .. x_istore_img_stg_table.COUNT
         LOOP
            BEGIN
               -- Perform validations
               x_error_code := data_validations(x_istore_img_stg_table (i));
               dbg_low('x_error_code for '|| x_istore_img_stg_table (i).record_number|| ' is ' || x_error_code);
               update_record_status (x_istore_img_stg_table (i), x_error_code);
               xx_emf_pkg.propagate_error (x_error_code);
            EXCEPTION
              -- If HIGH error then it will be propagated to the next level
              -- IF the process has to continue maintain it as a medium severity
              WHEN xx_emf_pkg.G_E_REC_ERROR THEN
                 dbg_high(xx_emf_cn_pkg.CN_REC_ERR);
              WHEN xx_emf_pkg.G_E_PRC_ERROR THEN
                 dbg_high('Process Level Error in Data Validations');
                 update_stg_records (x_istore_img_stg_table);
                 RAISE_APPLICATION_ERROR (-20199, xx_emf_cn_pkg.CN_PRC_ERR);
              WHEN OTHERS THEN
                 xx_emf_pkg.error(xx_emf_cn_pkg.CN_MEDIUM
                                 ,xx_emf_cn_pkg.CN_TECH_ERROR
                                 ,xx_emf_cn_pkg.CN_EXP_UNHAND
                                 ,x_istore_img_stg_table (i).record_number);
            END;
         END LOOP;
         dbg_low('x_istore_img_stg_table.count ' || x_istore_img_stg_table.COUNT );
         update_stg_records( x_istore_img_stg_table);
         x_istore_img_stg_table.DELETE;
         EXIT WHEN c_xx_istore_img_stg%NOTFOUND;
      END LOOP;

      IF c_xx_istore_img_stg%ISOPEN THEN
          CLOSE c_xx_istore_img_stg;
      END IF;

      dbg_low(G_REQUEST_ID || ' : Before Data Derivations');
      -- Once data-validations are complete loop through the pre-interface records
      -- and perform data derivations on this table

      -- Set the stage to data derivations
      /*****************************************/
      set_stage (xx_emf_cn_pkg.CN_DERIVE);
      OPEN c_xx_istore_img_stg ( xx_emf_cn_pkg.CN_VALID);
      LOOP
      FETCH c_xx_istore_img_stg
      BULK COLLECT INTO x_istore_img_stg_table LIMIT xx_emf_cn_pkg.CN_BULK_COLLECT;
         FOR i IN 1 .. x_istore_img_stg_table.COUNT
         LOOP
            BEGIN
               -- Perform Dervations
               x_error_code := data_derivations(x_istore_img_stg_table (i));
               dbg_low('x_error_code for '|| x_istore_img_stg_table (i).record_number|| ' is ' || x_error_code);
               update_record_status (x_istore_img_stg_table (i), x_error_code);
               xx_emf_pkg.propagate_error (x_error_code);
            EXCEPTION
              -- If HIGH error then it will be propagated to the next level
              -- IF the process has to continue maintain it as a medium severity
              WHEN xx_emf_pkg.G_E_REC_ERROR THEN
                 dbg_high(xx_emf_cn_pkg.CN_REC_ERR);
              WHEN xx_emf_pkg.G_E_PRC_ERROR THEN
                 dbg_high('Process Level Error in Data Derivations');
                 update_stg_records (x_istore_img_stg_table);
                 RAISE_APPLICATION_ERROR (-20199, xx_emf_cn_pkg.CN_PRC_ERR);
              WHEN OTHERS THEN
                 xx_emf_pkg.error(xx_emf_cn_pkg.CN_MEDIUM
                                 ,xx_emf_cn_pkg.CN_TECH_ERROR
                                 ,xx_emf_cn_pkg.CN_EXP_UNHAND
                                 ,x_istore_img_stg_table (i).record_number);
            END;
         END LOOP;
         dbg_low('x_istore_img_stg_table.count ' || x_istore_img_stg_table.COUNT );
         update_stg_records( x_istore_img_stg_table);
         x_istore_img_stg_table.DELETE;
         EXIT WHEN c_xx_istore_img_stg%NOTFOUND;
      END LOOP;

      IF c_xx_istore_img_stg%ISOPEN THEN
          CLOSE c_xx_istore_img_stg;
      END IF;

      -- Set the stage to Post Validations
      /******************************************/
      set_stage (xx_emf_cn_pkg.CN_POSTVAL);

      -- Change the validations package to the appropriate package name
      -- Modify the parameters as required
      -- DO NOT CHANGE ANYTHING ELSE IN THE CODE
      -- PRE_VALIDATIONS SHOULD BE RETAINED
      dbg_low('Calling post_validations ..');
      x_error_code := post_validations();
      dbg_med('After post-validations X_ERROR_CODE : ' || X_ERROR_CODE);
      -- Update mark records complete for staging records
      mark_records_complete(xx_emf_cn_pkg.CN_POSTVAL);
      dbg_med('After mark_records_complete post-validations X_ERROR_CODE ' || X_ERROR_CODE);
      xx_emf_pkg.propagate_error (x_error_code);

      -- Set the stage to Process
      /******************************************/
      set_stage (xx_emf_cn_pkg.CN_PROCESS_DATA);

      IF g_validate_flag = FALSE THEN
         dbg_low('Calling process_data');
         x_error_code := process_data();
         dbg_med('After post-process_data X_ERROR_CODE : ' || X_ERROR_CODE);
         mark_records_complete(xx_emf_cn_pkg.CN_PROCESS_DATA);
         dbg_med('After mark_records_complete X_ERROR_CODE'||X_ERROR_CODE);
         xx_emf_pkg.propagate_error ( x_error_code);
      END IF;

      update_record_count;
      xx_emf_pkg.create_report;

   EXCEPTION
      WHEN xx_emf_pkg.G_E_ENV_NOT_SET THEN
         xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Checking for G_E_ENV_NOT_SET');
         fnd_file.put_line ( fnd_file.output, xx_emf_pkg.CN_ENV_NOT_SET);
         x_retcode := xx_emf_cn_pkg.CN_REC_ERR;
         update_record_count;
         xx_emf_pkg.create_report;
      WHEN xx_emf_pkg.G_E_REC_ERROR THEN
         x_retcode := xx_emf_cn_pkg.CN_REC_ERR;
         update_record_count;
         xx_emf_pkg.create_report;
      WHEN xx_emf_pkg.G_E_PRC_ERROR THEN
         x_retcode := xx_emf_cn_pkg.CN_PRC_ERR;
         update_record_count;
         xx_emf_pkg.create_report;
      WHEN OTHERS THEN
         x_retcode := xx_emf_cn_pkg.CN_PRC_ERR;
         update_record_count;
         xx_emf_pkg.create_report;
   END main;

END xx_istore_image_conversion_pkg;
/


GRANT EXECUTE ON APPS.XX_ISTORE_IMAGE_CONVERSION_PKG TO INTG_XX_NONHR_RO;
