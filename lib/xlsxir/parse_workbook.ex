defmodule Xlsxir.ParseWorkbook do
  @moduledoc """
  Holds the SAX event instructions for parsing style data via `Xlsxir.SaxParser.parse/2`
  """

  @doc """
  sheets has multiple sheet map which consists of name, sheet_id and rid
  """
  defstruct sheets: [], tid: nil

  def sax_event_handler(:startDocument, _state) do
    %__MODULE__{tid: GenServer.call(Xlsxir.StateManager, :new_table)}
  end

  def sax_event_handler({:startElement, _, 'sheet', _, xml_attrs}, state) do
    sheet =
      Enum.reduce(xml_attrs, %{name: nil, sheet_id: nil, rid: nil}, fn attr, sheet ->
        case attr do
          {:attribute, 'name', _, _, name} ->
            %{sheet | name: name |> to_string}

          {:attribute, 'sheetId', _, _, sheet_id} ->
            {sheet_id, _} = sheet_id |> to_string |> Integer.parse()
            %{sheet | sheet_id: sheet_id}

          {:attribute, 'id', _, _, rid} ->
            "rId" <> rid = rid |> to_string
            {rid, _} = Integer.parse(rid)
            %{sheet | rid: rid}

          _ ->
            sheet
        end
      end)

    %__MODULE__{state | sheets: [sheet | state.sheets]}
  end

  def sax_event_handler(:endDocument, %__MODULE__{tid: tid} = state) do
    state.sheets
    |> Enum.reverse()
    |> Enum.with_index(1)
    |> Enum.each(fn {%{name: name}, index} ->
      :ets.insert(tid, {index, name})
    end)

    state
  end

  def sax_event_handler(_, state), do: state
end
