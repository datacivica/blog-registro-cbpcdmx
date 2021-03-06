# Author: JRR
# Maintainers: JRR, OE
# Copyright:   2022, Data Cívica GPL v2 or later
# ===========================================================
# desp-cdmx/descriptives/src/descriptives.R



# Paquetes ----------------------------------------------------------------
if(!require('pacman')) {install.packages('pacman')}
pacman::p_load(tidyverse, sf, here, svglite, scales, treemapify, reshape2, rcolorbrewer, readxl,
               biscale, cowplot, lubridate, patchwork)




# Files -------------------------------------------------------------------
files <- list(registro_cbpcdmx_clean = here("import", "output", "registro_cdmx_clean_dic.rds"),
              proyecciones_conapo = here("descriptives", "input", "base_municipios_final_datos_01.csv"),
              shp_cdmx = here("descriptives", "input", "09mun.shp"),
              escolaridad_censo_cdmx = here("censo", "output", "escolaridad_censo_cdmx.rds"),
              casos_registrados = here("descriptives", "output", "casos_registrados."),
              perfiles_desp = here("descriptives", "output", "perfiles_desp."),
              perfiles_desp_estatus = here("descriptives", "output", "perfiles_desp_estatus."),
              tree_map_escolaridad = here("descriptives", "output", "escolaridad_desp."),
              tree_map_escolaridad_estatus = here("descriptives", "output", "escolaridad_desp_estatus."),
              tree_map_civil = here("descriptives", "output", "civil_desp."),
              mapa_desp_totales = here("descriptives", "output", "mapa_desp_totales."),
              mapa_desp_tasas = here("descriptives", "output", "mapa_desp_tasas."),
              lugar_localizacion = here("descriptives", "output", "lugar_localizacion."))
              


devices <- c("png", "svg")


# Datos  ------------------------------------------------------------------
registro_cbpcdmx_clean <- read_rds(files$registro_cbpcdmx_clean)

shp_cdmx <- st_read(files$shp_cdmx)

poblacion_conapo <- read_csv(files$proyecciones_conapo) %>% 
   filter(NOM_ENT == "Ciudad de MÈxico") %>% 
   filter(`A—O` == 2021) %>% 
   group_by(CLAVE_ENT, MUN, `A—O`) %>% 
   summarise(total_poblacion = sum(POB)) %>% 
   ungroup() %>% 
   mutate(
      CVEGEO = case_when(
         MUN == "¡lvaro ObregÛn" ~ "09010", 
         MUN == "Azcapotzalco" ~ "09002", 
         MUN == "Benito Ju·rez" ~ "09014", 
         MUN == "Coyoac·n" ~ "09003", 
         MUN == "Cuajimalpa de Morelos" ~ "09004", 
         MUN == "CuauhtÈmoc" ~ "09015", 
         MUN == "Gustavo A. Madero" ~ "09005", 
         MUN == "Iztacalco" ~ "09006", 
         MUN == "Iztapalapa" ~ "09007", 
         MUN == "La Magdalena Contreras" ~ "09008", 
         MUN == "Miguel Hidalgo" ~ "09016", 
         MUN == "Milpa Alta" ~ "09009", 
         MUN == "Tlalpan" ~ "09012", 
         MUN == "Tl·huac" ~ "09011", 
         MUN == "Venustiano Carranza" ~ "09017", 
         MUN == "Xochimilco" ~ "09013", 
      ))

escolaridad_censo_cdmx <- read_rds(files$escolaridad_censo_cdmx)

# Periodos de registro ----------------------------------------------------

registro_cbpcdmx_clean %>% 
   group_by(year_desaparicion) %>%  
   mutate(year_desaparicion = as.character(year_desaparicion),
          year_desaparicion = case_when(year_desaparicion %in% 1966:2013 ~ "previo a 2013", 
                                       T ~ year_desaparicion),
          year_desaparicion = factor(year_desaparicion,
                              levels = c("previo a 2013",
                                         "2014",
                                         "2015",
                                         "2016",
                                         "2017",
                                         "2018",
                                         "2019",
                                         "2020",
                                         "2021"))) %>% 
   summarize(total=n()) %>% 
   na.omit() %>% 
   ggplot(aes(year_desaparicion, total)) +
   geom_col(fill = "#F85A3E") +
   geom_label(aes(label= total), family="Courier New") +
   theme_minimal(base_family = "Courier New") +
   theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
         plot.title = element_text(face = "bold", hjust = 0.5),
         plot.subtitle = element_text(hjust = 0.5),
         axis.text.x = element_text(face = "bold")) +
   labs(y = NULL, x= NULL, 
        title = "Casos de personas desaparecidas registradas por la \n Comisión de Búsqueda de personas de la CDMX")
   
   
walk(devices, ~ ggsave(filename = file.path(paste0(files$casos_registrados, .x)),
                       device = .x, width = 14, height = 10))



# Análisis quiénes son ----------------------------------------------------------------

# quiénes son sin status 
registro_cbpcdmx_clean %>% 
      mutate(
            grupo_edad = case_when(edad<12 ~ "Menores de 12 años",
                                   edad %in% 12:17 ~ "De 12 a 17 años",
                                   edad %in% 18:23 ~ "De 18 a 23 años",
                                   edad %in% 24:29 ~ "De 24 a 29 años",
                                   edad %in% 30:44 ~ "De 30 a 44 años",
                                   edad %in% 45:59 ~ "De 45 a 59 años",
                                   edad>=60 ~ "60 años o más"),
            grupo_edad = factor(grupo_edad,
                                levels = c("Menores de 12 años",
                                           "De 12 a 17 años",
                                           "De 18 a 23 años",
                                           "De 24 a 29 años",
                                           "De 30 a 44 años",
                                           "De 45 a 59 años",
                                           "60 años o más"))) %>% 
      group_by(sexo, grupo_edad) %>%
      summarize(total=n()) %>%
      mutate(den=sum(total, na.rm=T)) %>%
      ungroup() %>%
      mutate(per=round((total/den)*100, 1)) %>%
      na.omit()%>%
      mutate(order_edad= as.numeric(grupo_edad)) %>% 
      ggplot(data=., aes(x = sexo, y = reorder(grupo_edad, -order_edad), fill = per)) +
      geom_tile(color="black") +
      scale_fill_gradient(low="#F9E0D9", high="#F85A3E", name = "Porcentaje")+ 
      labs(title="Edad y sexo de personas desaparecidas en la Ciudad de México",
           subtitle = "Registradas por la Comisión de Búsqueda de la CDMX",
           x="", y="", fill="") +
      geom_text(aes(label=paste0(per, "%")), size=3.5, hjust=.2, vjust=.2, color="black") +
      theme_minimal(base_family = "Courier New") +
      theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
            plot.title = element_text(face = "bold", hjust = 0.5),
            plot.subtitle = element_text(hjust = 0.5),
            axis.text.y = element_text(face = "bold", size=10.5),
            axis.text.x = element_text(face = "bold", size=10.5)) +
      scale_x_discrete(position = "top")

walk(devices, ~ ggsave(filename = file.path(paste0(files$perfiles_desp, .x)),
                       device = .x, width = 20, height = 18))


# quiénes son con estatus 
registro_cbpcdmx_clean %>% 
      mutate(
            grupo_edad = case_when(edad<12 ~ "Menores de 12 años",
                                   edad %in% 12:17 ~ "De 12 a 17 años",
                                   edad %in% 18:23 ~ "De 18 a 23 años",
                                   edad %in% 24:29 ~ "De 24 a 29 años",
                                   edad %in% 30:44 ~ "De 30 a 44 años",
                                   edad %in% 45:59 ~ "De 45 a 59 años",
                                   edad>=60 ~ "60 años o más"),
            grupo_edad = factor(grupo_edad,
                                levels = c("Menores de 12 años",
                                           "De 12 a 17 años",
                                           "De 18 a 23 años",
                                           "De 24 a 29 años",
                                           "De 30 a 44 años",
                                           "De 45 a 59 años",
                                           "60 años o más")),
            condicion_localizacion = factor(condicion_localizacion,
                                            levels = c("con vida",
                                                       "sin vida",
                                                       "sigue desaparecida"))) %>% 
      group_by(sexo, condicion_localizacion, grupo_edad) %>%
      summarize(total=n()) %>%
      mutate(den=sum(total, na.rm=T)) %>%
      ungroup() %>%
      mutate(per=round((total/den)*100, 1)) %>%
      na.omit()%>%
      mutate(order_edad= as.numeric(grupo_edad)) %>% 
      ggplot(data=., aes(x = sexo, y = reorder(grupo_edad, -order_edad), fill = per)) +
      geom_tile(color="black") +
      scale_fill_gradient(low="#F9E0D9", high="#F85A3E", name = "Porcentaje")+ 
      labs(title="Edad y sexo de personas desaparecidas en la Ciudad de México",
           subtitle = "con base en su estatus de localización",
           x="", y="", fill="") +
      geom_text(aes(label=paste0(per, "%")), size=3.5, hjust=.2, vjust=.2, color="black")+
      theme_minimal(base_family = "Courier New") +
      theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
            plot.title = element_text(face = "bold", hjust = 0.5),
            plot.subtitle = element_text(hjust = 0.5),
            axis.text.y = element_text(face = "bold", size=10.5),
            axis.text.x = element_text(face = "bold", size=10.5)) +
      scale_x_discrete(position = "top")+
      facet_wrap(~ condicion_localizacion)

walk(devices, ~ ggsave(filename = file.path(paste0(files$perfiles_desp_estatus, .x)),
                       device = .x, width = 20, height = 18))



# Escolaridad censo 
escolaridad_censo_cdmx %>% 
      ungroup() %>%
      mutate(per=round((total/pob)*100, 0)) %>% 
      ggplot(aes(fill = NIVACAD, area = per, label = paste0(NIVACAD, "\n", per))) +
      geom_treemap() +
      geom_treemap_text( aes(label=paste0(NIVACAD, "\n", per, "% (", total, ")")), colour ="black", 
                         place = "centre", size = 12, face = "bold",
                         family = "Courier New Bold") +
      scale_fill_brewer(palette = "Set3") +
      labs(title= "Escolaridad de la población en CDMX",
           subtitle = "En porcentaje") +
      theme_minimal(base_family = "Courier New") +
      theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
            plot.title = element_text(face = "bold", hjust = 0.5),
            plot.subtitle = element_text(hjust = 0.5),
            axis.text.y = element_blank(),
            axis.text.x = element_text(face = "bold")) +
      theme(legend.position = "none") 



# Escolaridad sin estatus 
registro_cbpcdmx_clean %>% 
      mutate(condicion_localizacion = factor(condicion_localizacion,
                                             levels = c("con vida",
                                                        "sin vida",
                                                        "sigue desaparecida"))) %>% 
      group_by(escolaridad) %>% 
      summarize(total=n()) %>% 
      na.omit() %>% 
      mutate(den=sum(total, na.rm=T)) %>%
      ungroup() %>%
      mutate(per=round((total/den)*100, 0)) %>% 
      arrange(-per) %>% 
      ggplot(aes(fill = escolaridad, area = per, label = paste0(escolaridad, "\n", per))) +
      geom_treemap() +
      geom_treemap_text( aes(label=paste0(escolaridad, "\n", per, "% (", total, ")")), colour ="black", 
                         place = "centre", size = 12, face = "bold",
                         family = "Courier New Bold") +
      scale_fill_brewer(palette = "Set3") +
      labs(title= "Escolaridad de personas desaparecidas registradas por la Comisión de Búsqueda de la CDMX") +
      theme_minimal(base_family = "Courier New") +
      theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
            plot.title = element_text(face = "bold", hjust = 0.5),
            plot.subtitle = element_text(hjust = 0.5),
            axis.text.y = element_blank(),
            axis.text.x = element_text(face = "bold")) +
      theme(legend.position = "none") 

walk(devices, ~ ggsave(filename = file.path(paste0(files$tree_map_escolaridad, .x)),
                       device = .x, width = 14, height = 10))

# escolaridad con estatus
registro_cbpcdmx_clean %>% 
   mutate(condicion_localizacion = factor(condicion_localizacion,
                                           levels = c("con vida",
                                                      "sin vida",
                                                      "sigue desaparecida"))) %>% 
   group_by(condicion_localizacion, escolaridad) %>% 
   summarize(total=n()) %>% 
   na.omit() %>% 
   mutate(den=sum(total, na.rm=T)) %>%
   ungroup() %>%
   mutate(per=round((total/den)*100, 0)) %>% 
   arrange(-per) %>% 
   ggplot(aes(fill = escolaridad, area = per, label = paste0(escolaridad, "\n", per))) +
      geom_treemap() +
      geom_treemap_text( aes(label=paste0(escolaridad, "\n", per, "% (", total, ")")), colour ="black", 
                         place = "centre", size = 12, face = "bold",
                        family = "Courier New Bold") +
      scale_fill_brewer(palette = "Set3") +
      facet_wrap(~ condicion_localizacion) +
      labs(title= "Escolaridad de personas desaparecidas registradas por la Comisión de Búsqueda de la CDMX",
           subtitle = "Con base en su estatus de localización") +
      theme_minimal(base_family = "Courier New") +
      theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
            plot.title = element_text(face = "bold", hjust = 0.5),
            plot.subtitle = element_text(hjust = 0.5),
            axis.text.y = element_blank(),
            axis.text.x = element_text(face = "bold")) +
      theme(legend.position = "none") 

walk(devices, ~ ggsave(filename = file.path(paste0(files$tree_map_escolaridad_estatus, .x)),
                       device = .x, width = 14, height = 10))


# Estado civil
registro_cbpcdmx_clean %>% 
   mutate(condicion_localizacion = factor(condicion_localizacion,
                                          levels = c("con vida",
                                                     "sin vida",
                                                     "sigue desaparecida"))) %>% 
   group_by(sexo, estado_civil) %>% 
   summarize(total=n()) %>% 
   na.omit() %>% 
   mutate(den=sum(total, na.rm=T)) %>%
   ungroup() %>%
   mutate(per=round((total/den)*100, 0)) %>% 
   arrange(-per) %>% 
   ggplot(aes(fill = estado_civil, area = per, label = paste0(estado_civil, "\n", per))) +
   geom_treemap() +
   geom_treemap_text( aes(label=paste0(estado_civil, "\n", per, "%")), colour ="black", 
                      place = "centre", size = 12, face = "bold",
                      family = "Courier New Bold") +
   scale_fill_brewer(palette = "Set3") +
   facet_wrap(~ sexo) +
   labs(title= "Estado civil de personas desaparecidas registradas por la Comisión de Búsqueda de la CDMX",
        subtitle = "En porcentaje y con base en su sexo") +
   theme_minimal(base_family = "Courier New") +
   theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
         plot.title = element_text(face = "bold", hjust = 0.5),
         plot.subtitle = element_text(hjust = 0.5),
         axis.text.y = element_blank(),
         axis.text.x = element_text(face = "bold")) +
   theme(legend.position = "none") 

walk(devices, ~ ggsave(filename = file.path(paste0(files$tree_map_civil, .x)),
                       device = .x, width = 14, height = 10))



# Dónde desaparecen -------------------------------------------------------

# preparar shape con conapo y datos cbpcdmx 
shp_cdmx <- shp_cdmx %>%
   left_join(poblacion_conapo,
             by = c("CVEGEO" = "CVEGEO")) 


cases_per_muni <- registro_cbpcdmx_clean %>%
   group_by(cv_mun_desp) %>%
   count(cv_mun_desp) %>% 
   ungroup() 


# Datos para mapa
mapa_registro <- shp_cdmx %>%
   left_join(cases_per_muni,
             by = c("CVE_MUN" = "cv_mun_desp")) %>% 
   mutate(tasa_desp = n*(100000/total_poblacion),
          tasa_quart = ntile(tasa_desp, 4),
          tasa_quart = as.factor(tasa_quart),
          quart_rangos = case_when(
                tasa_quart == "1" ~ "7.88-15.97",
                tasa_quart == "2" ~ "17.61-19.00",
                tasa_quart == "3" ~ "19.17-22.44",
                tasa_quart == "4" ~ "23.58-45.14"
          ),
          quart_rangos = factor(quart_rangos,
                              levels = c("23.58-45.14",
                                         "19.17-22.44",
                                         "17.61-19.00",
                                         "7.88-15.97"))
          ) %>% 
   st_transform(mapa_registro, crs = "+proj=longlat +ellps=WGS72 +no_defs")


# mapear desp
centroides <- st_coordinates(st_centroid(mapa_registro)) %>% as.tibble()



# totales
mapa_registro %>% 
   bind_cols(centroides) %>% 
   ggplot() +
   geom_sf(aes(geometry = geometry, fill = n), size = 0.2, color = "black") +
   geom_text(aes(X, Y, label = CVEGEO), size = 2) +
   scale_fill_continuous(low = "#ffeda0", high = "#f03b20", na.value = "white", name = "Total de casos") +
   labs(title = "Total de personas desaparecidas en CDMX por alcaldía",
        subtitle = "Casos observados por Comisión de Búsqueda de Personas de la ciudad") +
   theme_void() +
   theme(plot.title = element_text(hjust = 0.5, face = "bold", size = 14),
         plot.subtitle = element_text(hjust = 0.5, face = "bold", size = 10),
         legend.position = "right")



walk(devices, ~ ggsave(filename = file.path(paste0(files$mapa_desp_totales, .x)),
                       device = .x, width = 14, height = 10))


# tasas
mapa_registro %>% 
      mutate(MUN = ifelse(MUN == "¡lvaro ObregÛn", "Álvaro Obregón",
                          MUN),
             MUN = ifelse(MUN == "Benito Ju·rez", "Benito Juárez",
                          MUN),
             MUN = ifelse(MUN == "Coyoac·n", "Coyoacán",
                          MUN),
             MUN = ifelse(MUN == "CuauhtÈmoc", "Cuauhtémoc",
                          MUN),
             MUN = ifelse(MUN == "Tl·huac", "Tláhuac",
                          MUN)) %>% 
      bind_cols(centroides) %>% 
   ggplot() +
   geom_sf(aes(geometry = geometry, fill = quart_rangos), size = 0.2, color = "black") +
   geom_text(aes(X, Y, label = MUN), size = 2) +
      scale_fill_manual(values= c("#63C132", "#9EE37D", "#AAEFDF", "#CFFCFF"),
                        labels = c("23.58-45.14", "19.17-22.44", "17.61-19.00", "7.88-15.97"),
                        name = "Tasa por cada 100 mil habitantes"
                        ) +
   labs(title = "Tasa anual de desapariciones en CDMX por alcaldía",
        subtitle = "Casos observados por Comisión de Búsqueda de Personas de la ciudad") +
   theme_void() +
   theme(plot.title = element_text(hjust = 0.5, face = "bold", size = 14),
         plot.subtitle = element_text(hjust = 0.5, face = "bold", size = 10),
         legend.position = "right")



walk(devices, ~ ggsave(filename = file.path(paste0(files$mapa_desp_tasas, .x)),
                       device = .x, width = 14, height = 10))



# Cómo se localizan  ------------------------------------------------------

# Fechas 
registro_cbpcdmx_clean %>% 
   mutate(dif_time = difftime(registro_cbpcdmx_clean$fecha_de_desaparicion,registro_cbpcdmx_clean$fecha_de_localizacion,units=c("days"))) %>%
   group_by(sexo, condicion_localizacion) %>% 
   filter(condicion_localizacion != "sigue desaparecida") %>% 
   summarise(mean = mean(dif_time, na.rm = T)) 



# lugar de localizacion con vida 
p1 <- registro_cbpcdmx_clean %>% 
   filter(condicion_localizacion == "con vida") %>% 
   group_by(tipo_de_lugar_de_la_localizacion) %>% 
   summarize(total=n()) %>% 
   na.omit() %>% 
   mutate(den=sum(total, na.rm=T)) %>%
   ungroup() %>%
   mutate(per=round((total/den)*100, 2)) %>% 
  mutate(tipo_de_lugar_de_la_localizacion = reorder(tipo_de_lugar_de_la_localizacion, per)) %>%
   ggplot(aes(tipo_de_lugar_de_la_localizacion, per)) +
   geom_col(fill = "#F85A3E") +
   geom_text(aes(label=paste0(per, "%")), size=2.5, hjust=.2, vjust=.2, color="black") +
   coord_flip() +
   labs(title= NULL,
        subtitle = "con vida",
        x = NULL, y = NULL) +
   theme_minimal(base_family = "Courier New") +
   theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
         plot.title = element_text(face = "bold", hjust = 0.5),
         plot.subtitle = element_text(hjust = 0.5),
         axis.text.x = element_text(face = "bold")) +
   theme(legend.position = "none") 

# lugar de localizacion sin vida 
p2 <- registro_cbpcdmx_clean %>% 
   filter(condicion_localizacion == "sin vida") %>% 
   group_by(tipo_de_lugar_de_la_localizacion) %>% 
   summarize(total=n()) %>% 
   na.omit() %>% 
   mutate(den=sum(total, na.rm=T)) %>%
   ungroup() %>%
   mutate(per=round((total/den)*100, 2)) %>% 
   mutate(tipo_de_lugar_de_la_localizacion = reorder(tipo_de_lugar_de_la_localizacion, per)) %>%
   ggplot(aes(tipo_de_lugar_de_la_localizacion, per)) +
   geom_col(fill = "#F85A3E") +
   geom_text(aes(label=paste0(per, "%")), size=2.5, hjust=.2, vjust=.2, color="black") +
   coord_flip() +
   labs(title= NULL,
        subtitle = "sin vida",
        x = NULL, y = "porcentaje") +
   theme_minimal(base_family = "Courier New") +
   theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
         plot.title = element_text(face = "bold", hjust = 0.5),
         plot.subtitle = element_text(hjust = 0.5),
         axis.text.x = element_text(face = "bold")) +
   theme(legend.position = "none") 

patchwork <- p1 / p2 
patchwork + 
   plot_annotation(
   title = "Lugar de localización de las personas reportadas como desaparecidas \n ante la Comisión de Búsqueda de Personas de la CDMX"
   ) &
   theme(plot.title = element_text(face = "bold", hjust = 0.5))

walk(devices, ~ ggsave(filename = file.path(paste0(files$lugar_localizacion, .x)),
                       device = .x, width = 14, height = 10))


# FIN  