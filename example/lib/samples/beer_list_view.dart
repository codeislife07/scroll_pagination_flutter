import 'package:paginationdemo/remote/beer_summary.dart';
import 'package:paginationdemo/remote/remote_api.dart';
import 'package:paginationdemo/samples/common/beer_list_item.dart';
import 'package:flutter/material.dart';
import 'package:scroll_pagination_flutter/pagination_flutter.dart';

class BeerListView extends StatefulWidget {
  @override
  _BeerListViewState createState() => _BeerListViewState();
}

class _BeerListViewState extends State<BeerListView> {
  static const _pageSize = 20;

  final PagingController<int, BeerSummary> _pagingController =
      PagingController(firstPageKey: 1);

  @override
  void initState() {
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
    super.initState();
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      final newItems = await RemoteApi.getBeerList(pageKey, _pageSize);

      final isLastPage = newItems.length < _pageSize;
      if (isLastPage) {
        _pagingController.appendLastPage(newItems);
      } else {
        final nextPageKey = pageKey + 1;
        _pagingController.appendPage(newItems, nextPageKey);
      }
    } catch (error) {
      _pagingController.error = error;
    }
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
        onRefresh: () => Future.sync(
          () => _pagingController.refresh(),
        ),
        child: PagedListView<int, BeerSummary>.separated(
          pagingController: _pagingController,
          builderDelegate: PagedChildBuilderDelegate<BeerSummary>(
            animateTransitions: true,
            singleitemBuilder: (context, item, index) => BeerListItem(
              beer: item,
            ),
          ),
          separatorBuilder: (context, index) => const Divider(),
        ),
      );

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }
}
