// Copyright 2007 Mitchell Foral mitchell<att>caladbolg.net. See LICENSE.

#include "textadept.h"

GtkWidget *pm_view, *pm_entry, *pm_container;
GtkTreeStore *pm_store;

static int pm_search_equal_func(GtkTreeModel *model, int col, const char *key,
                                GtkTreeIter *iter, gpointer);
static int pm_sort_iter_compare_func(GtkTreeModel *model, GtkTreeIter *a,
                                     GtkTreeIter *b, gpointer);
static void pm_entry_activated(GtkWidget *widget, gpointer);
static bool pm_entry_keypress(GtkWidget *, GdkEventKey *event, gpointer);
static void pm_row_expanded(GtkTreeView *, GtkTreeIter *iter,
                            GtkTreePath *path, gpointer);
static void pm_row_collapsed(GtkTreeView *, GtkTreeIter *iter,
                             GtkTreePath *path, gpointer);
static void pm_row_activated(GtkTreeView *, GtkTreePath *, GtkTreeViewColumn *,
                             gpointer);
static bool pm_button_press(GtkTreeView *, GdkEventButton *event, gpointer);
static bool pm_popup_menu(GtkWidget *, gpointer);
static void pm_menu_activate(GtkWidget *menu_item, gpointer);

GtkWidget* pm_create_ui() {
  pm_container = gtk_vbox_new(false, 1);

  pm_entry = gtk_entry_new();
  gtk_widget_set_name(pm_entry, "textadept-pm-entry");
  gtk_box_pack_start(GTK_BOX(pm_container), pm_entry, false, false, 0);

  pm_store = gtk_tree_store_new(3, G_TYPE_STRING, G_TYPE_STRING, G_TYPE_STRING);
  GtkTreeSortable *sortable = GTK_TREE_SORTABLE(pm_store);
  gtk_tree_sortable_set_sort_column_id(sortable, 1, GTK_SORT_ASCENDING);
  gtk_tree_sortable_set_sort_func(sortable, 1, pm_sort_iter_compare_func,
                                  GINT_TO_POINTER(1), NULL);

  pm_view = gtk_tree_view_new_with_model(GTK_TREE_MODEL(pm_store));
  g_object_unref(pm_store);
  gtk_widget_set_name(pm_view, "textadept-pm-view");
  gtk_tree_view_set_headers_visible(GTK_TREE_VIEW(pm_view), false);
  gtk_tree_view_set_enable_search(GTK_TREE_VIEW(pm_view), true);
  gtk_tree_view_set_search_column(GTK_TREE_VIEW(pm_view), 2);
  gtk_tree_view_set_search_equal_func(GTK_TREE_VIEW(pm_view),
                                      pm_search_equal_func, NULL, NULL);

  GtkTreeViewColumn *column = gtk_tree_view_column_new();
  GtkCellRenderer *renderer;
  renderer = gtk_cell_renderer_pixbuf_new(); // pixbuf
  gtk_tree_view_column_pack_start(column, renderer, FALSE);
  gtk_tree_view_column_set_attributes(column, renderer, "stock-id", 0, NULL);
  renderer = gtk_cell_renderer_text_new(); // markup text
  gtk_tree_view_column_pack_start(column, renderer, TRUE);
  gtk_tree_view_column_set_attributes(column, renderer, "markup", 2, NULL);
  gtk_tree_view_append_column(GTK_TREE_VIEW(pm_view), column);

  GtkWidget *scrolled = gtk_scrolled_window_new(NULL, NULL);
  gtk_scrolled_window_set_policy(GTK_SCROLLED_WINDOW(scrolled),
                                 GTK_POLICY_AUTOMATIC, GTK_POLICY_AUTOMATIC);
  gtk_container_add(GTK_CONTAINER(scrolled), pm_view);
  gtk_box_pack_start(GTK_BOX(pm_container), scrolled, true, true, 0);

  g_signal_connect(G_OBJECT(pm_entry), "activate",
                   G_CALLBACK(pm_entry_activated), 0);
  g_signal_connect(G_OBJECT(pm_entry), "key_press_event",
                   G_CALLBACK(pm_entry_keypress), 0);
  g_signal_connect(G_OBJECT(pm_view), "row_expanded",
                   G_CALLBACK(pm_row_expanded), 0);
  g_signal_connect(G_OBJECT(pm_view), "row_collapsed",
                   G_CALLBACK(pm_row_collapsed), 0);
  g_signal_connect(G_OBJECT(pm_view), "row_activated",
                   G_CALLBACK(pm_row_activated), 0);
  g_signal_connect(G_OBJECT(pm_view), "button_press_event",
                   G_CALLBACK(pm_button_press), 0);
  g_signal_connect(G_OBJECT(pm_view), "popup-menu",
                   G_CALLBACK(pm_popup_menu), 0);
  return pm_container;
}

void pm_open_parent(GtkTreeIter *iter, GtkTreePath *path) {
  l_pm_get_full_path(path);
  if (l_pm_get_contents_for(NULL, true)) l_pm_populate(iter);
  GtkTreeIter child;
  char *filename;
  gtk_tree_model_iter_nth_child(GTK_TREE_MODEL(pm_store), &child, iter, 0);
  gtk_tree_model_get(GTK_TREE_MODEL(pm_store), &child, 1, &filename, -1);
  if (strcmp(reinterpret_cast<const char*>(filename), "\0dummy") == 0)
    gtk_tree_store_remove(pm_store, &child);
  g_free(filename);
}

void pm_close_parent(GtkTreeIter *iter, GtkTreePath *) {
  GtkTreeIter child;
  gtk_tree_model_iter_nth_child(GTK_TREE_MODEL(pm_store), &child, iter, 0);
  while (gtk_tree_model_iter_has_child(GTK_TREE_MODEL(pm_store), iter))
    gtk_tree_store_remove(pm_store, &child);
  gtk_tree_store_append(pm_store, &child, iter);
  gtk_tree_store_set(pm_store, &child, 1, "\0dummy", -1);
}

void pm_activate_selection() {
  GtkTreeIter iter;
  GtkTreePath *path;
  GtkTreeViewColumn *column;
  gtk_tree_view_get_cursor(GTK_TREE_VIEW(pm_view), &path, &column);
  gtk_tree_model_get_iter(GTK_TREE_MODEL(pm_store), &iter, path);
  if (gtk_tree_model_iter_has_child(GTK_TREE_MODEL(pm_store), &iter))
    if (gtk_tree_view_row_expanded(GTK_TREE_VIEW(pm_view), path))
      gtk_tree_view_collapse_row(GTK_TREE_VIEW(pm_view), path);
    else
      gtk_tree_view_expand_row(GTK_TREE_VIEW(pm_view), path, false);
  else {
    l_pm_get_full_path(path);
    l_pm_perform_action();
  }
  gtk_tree_path_free(path);
}

void pm_popup_context_menu(GdkEventButton *event) {
  l_pm_popup_context_menu(event, G_CALLBACK(pm_menu_activate));
}

void pm_process_selected_menu_item(GtkWidget *menu_item) {
  GtkWidget *label = gtk_bin_get_child(GTK_BIN(menu_item));
  const char *text = gtk_label_get_text(GTK_LABEL(label));
  GtkTreePath *path;
  GtkTreeViewColumn *column;
  gtk_tree_view_get_cursor(GTK_TREE_VIEW(pm_view), &path, &column);
  l_pm_get_full_path(path);
  l_pm_perform_menu_action(text);
}

void pm_toggle_focus() {
  gtk_widget_grab_focus(
    GTK_WIDGET_HAS_FOCUS(focused_editor) ? pm_entry : focused_editor);
}

static int pm_search_equal_func(GtkTreeModel *model, int col, const char *key,
                                GtkTreeIter *iter, gpointer) {
  const char *text;
  gtk_tree_model_get(model, iter, col, &text, -1);
  return strstr(text, key) == NULL; // false is really a match like strcmp
}

static int pm_sort_iter_compare_func(GtkTreeModel *model, GtkTreeIter *a,
                                     GtkTreeIter *b, gpointer) {
  const char *a_text, *b_text;
  gtk_tree_model_get(model, a, 1, &a_text, -1);
  gtk_tree_model_get(model, b, 1, &b_text, -1);
  if (a_text == NULL && b_text == NULL) return 0;
  else if (a_text == NULL) return -1;
  else if (b_text == NULL) return 1;
  else return strcasecmp(a_text, b_text);
}

// Signals
static void pm_entry_activated(GtkWidget *widget, gpointer) {
  const char *entry_text = gtk_entry_get_text(GTK_ENTRY(widget));
  if (l_pm_get_contents_for(entry_text)) l_pm_populate();
}

static bool pm_entry_keypress(GtkWidget *, GdkEventKey *event, gpointer) {
  if (event->keyval == 0xff09 && event->state == GDK_CONTROL_MASK) {
    gtk_widget_grab_focus(focused_editor);
    return true;
  } else return false;
}

static void pm_row_expanded(GtkTreeView *, GtkTreeIter *iter,
                            GtkTreePath *path, gpointer) {
  pm_open_parent(iter, path);
}

static void pm_row_collapsed(GtkTreeView *, GtkTreeIter *iter,
                             GtkTreePath *path, gpointer) {
  pm_close_parent(iter, path);
}

static void pm_row_activated(GtkTreeView *, GtkTreePath *, GtkTreeViewColumn *,
                             gpointer) {
  pm_activate_selection();
}

static bool pm_button_press(GtkTreeView *, GdkEventButton *event, gpointer) {
  if (event->type != GDK_BUTTON_PRESS || event->button != 3) return false;
  pm_popup_context_menu(event); return true;
}

static bool pm_popup_menu(GtkWidget *, gpointer) {
  pm_popup_context_menu(NULL); return true;
}

static void pm_menu_activate(GtkWidget *menu_item, gpointer) {
  pm_process_selected_menu_item(menu_item);
}
