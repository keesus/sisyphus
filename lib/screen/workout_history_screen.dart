import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:sisyphus/db/db_helper.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class WorkoutHistoryScreen extends StatefulWidget {
  const WorkoutHistoryScreen({Key? key}) : super(key: key);

  @override
  State<WorkoutHistoryScreen> createState() => _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends State<WorkoutHistoryScreen> {

  late List<Map<String, dynamic>> setList;
  late Map<String, List> setListInGroup;
  late Map<String, List> setListInGroupInBodyparts;


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    initializeDateFormatting(Localizations.localeOf(context).languageCode);
  }


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    syncWorkoutDates();
    setList = [];
    setListInGroup = {};
  }


  Widget titleWithBodyparts(int k, int j) {
    List<String> temp = [];
    for(int i = 0; i < j; i++) {
      temp.add(setListInGroup.entries.toList()[k].value.toList()[i]['bodypart']);
    }

    List<String> bodypartsInSet = temp.toSet().toList();

    String result = '';
    bodypartsInSet.forEach((element) {
      result += element.toString() + ' ';
    });
    return Text(result);
  }
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
          appBar: AppBar(
            title: Text('운동 기록'),
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios),
              onPressed: () {Navigator.pop(context);},
            ),
            bottom: TabBar(
              tabs: [
                Tab(text: 'Stroke'),
                Tab(text: 'Overall'),
                Tab(text: 'Partial'),
              ],
            ),
          ),
          body: TabBarView(
              physics: const NeverScrollableScrollPhysics(),
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: ListView.builder(
                    // controller: _scrollController,
                      reverse: true,
                      shrinkWrap: true,
                      itemCount: setListInGroup.length,
                      itemBuilder: (BuildContext context, int index) {
                        return ExpansionTile(
                          initiallyExpanded: false,
                          subtitle: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              calDateDiffInString(setListInGroup.entries.toList()[index].value.toList().first['datediff'].ceil()),
                              titleWithBodyparts(index, setListInGroup.entries.toList()[index].value.toList().length)
                            ],
                          ),
                          title: Text(setListInGroup.keys.toList()[index].toString().substring(0,10) + '   ' + DateFormat.E('ko_KR').format(DateTime.parse(setListInGroup.keys.toList()[index]))),
                          children:[
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                columnSpacing: 8,
                                horizontalMargin: 0,
                                columns: _getColumns(),
                                rows: _getRows(index),
                              ),
                            )
                          ],
                        );
                      }),
                ),
                Container(),
                Container(),
              ]
          )
      ),
    );
  }

  Widget calDateDiffInString(int dateDiff) {
    switch(dateDiff) {
      case 0:
        return Text('오늘');
      case 1:
        return Text('어제');
      default:
        return Text(dateDiff.toString() + '일 전');
    }

  }
  List<DataColumn> _getColumns() {
    const TextStyle _style = TextStyle(fontSize: 12);
    final List<String> setHistoryDataDivisions = [
      '부위', '운동', '세트', '최소 중량' ,'최대 중량', '평균 중량', '최소 횟수', '최대 횟수', '평균 횟수', '볼륨'
    ];

    List<DataColumn> dataColumn = [];
    setHistoryDataDivisions
        .forEach((item) => dataColumn.add(DataColumn(label: Text(item, style: _style))));
    return dataColumn;
  }

  List<DataRow> _getRows(int index) {
    const TextStyle _style = TextStyle(fontSize: 12);

    List<DataRow> dataRow = [];
    for (int j = 0 ; j < setListInGroup.entries.toList()[index].value.length; j++) {
      List<DataCell> dataCells = [];
      dataCells.add(DataCell(Text(
          setListInGroup.entries.toList()[index].value.toList()[j]['bodypart']
              .toString(), style: _style)));
      dataCells.add(DataCell(ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 120),
        child: Text(
            setListInGroup.entries.toList()[index].value.toList()[j]['name']
                .toString(),
        overflow: TextOverflow.ellipsis, style: _style
        ),
      )));
      dataCells.add(DataCell(Text(
          setListInGroup.entries.toList()[index].value.toList()[j]['count']
              .toString(), style: _style)));
      dataCells.add(DataCell(Text(
          setListInGroup.entries.toList()[index].value.toList()[j]['minimum_weight']
              .toString() + 'kg', style: _style)));
      dataCells.add(DataCell(Text(
          setListInGroup.entries.toList()[index].value.toList()[j]['maximum_weight']
              .toString() + 'kg', style: _style)));
      dataCells.add(DataCell(Text(
          setListInGroup.entries.toList()[index].value.toList()[j]['average_weight']
              .toString() + 'kg', style: _style)));
      dataCells.add(DataCell(Text(
          setListInGroup.entries.toList()[index].value.toList()[j]['minimum_reps']
              .toString(), style: _style)));
      dataCells.add(DataCell(Text(
          setListInGroup.entries.toList()[index].value.toList()[j]['minimum_reps']
              .toString(), style: _style)));
      dataCells.add(DataCell(Text(
          setListInGroup.entries.toList()[index].value.toList()[j]['average_reps']
              .toString(), style: _style)));
      dataCells.add(DataCell(Text(
          setListInGroup.entries.toList()[index].value.toList()[j]['volumn']
              .toString() + 'kg', style: _style)));

      dataRow.add(DataRow(cells: dataCells));
    }
    return dataRow;

  }

  void syncWorkoutDates() async {
    var temp = await DBHelper.instance.getSetsInGroup();
    setState(() {
      setListInGroup = groupBy(temp, (obj) {
        return obj['created_at'].toString().substring(0,10);
      });
    });

  }

}
